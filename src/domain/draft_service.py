from __future__ import annotations

import logging
from json import JSONDecodeError
from typing import cast

from src.domain.dataset_preview import dataset_preview
from src.domain.draft_preview_llm import (
    apply_structured_fields_from_llm_text,
    build_draft_preview_prompt,
)
from src.domain.draft_v1_contract import (
    DraftPatchResult,
    DraftPreviewResult,
    has_inputs,
    is_v1_redeem_job,
    list_of_dicts,
    pending_inputs_upload_result,
    v1_contract_fields,
)
from src.domain.inputs_manifest import primary_dataset_details, read_manifest_json
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient
from src.domain.models import Draft, DraftDataSource, DraftVariableType, Job, JobStatus
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import JobStoreIOError, LLMArtifactsWriteError, LLMCallFailedError
from src.infra.input_exceptions import InputPathUnsafeError
from src.utils.json_types import JsonValue
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


class DraftService:
    """Draft preview service: load job → call LLM → persist → return."""

    def __init__(
        self,
        *,
        store: JobStore,
        llm: LLMClient,
        state_machine: JobStateMachine,
        workspace: JobWorkspaceStore,
    ):
        self._store = store
        self._llm = llm
        self._state_machine = state_machine
        self._workspace = workspace

    async def preview(self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str) -> Draft:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        return await self._preview_for_loaded_job(tenant_id=tenant_id, job=job)

    async def preview_v1(
        self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str
    ) -> DraftPreviewResult:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if is_v1_redeem_job(job_id) and not has_inputs(job):
            return pending_inputs_upload_result()
        draft = await self._preview_for_loaded_job(tenant_id=tenant_id, job=job)
        return DraftPreviewResult(draft=draft, pending=None)

    def patch_v1(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        field_updates: dict[str, JsonValue],
    ) -> DraftPatchResult:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        draft = job.draft
        if draft is None:
            draft = Draft(text="", created_at=utc_now().isoformat())
        updates: dict[str, object] = {}
        patched: list[str] = []

        outcome_var = field_updates.get("outcome_var")
        if isinstance(outcome_var, str):
            updates["outcome_var"] = outcome_var if outcome_var.strip() != "" else None
            patched.append("outcome_var")

        treatment_var = field_updates.get("treatment_var")
        if isinstance(treatment_var, str):
            updates["treatment_var"] = treatment_var if treatment_var.strip() != "" else None
            patched.append("treatment_var")

        controls = field_updates.get("controls")
        if isinstance(controls, list) and all(isinstance(item, str) for item in controls):
            controls_str = cast(list[str], controls)
            updates["controls"] = [item for item in controls_str if item.strip() != ""]
            patched.append("controls")

        default_overrides = field_updates.get("default_overrides")
        if isinstance(default_overrides, dict):
            updates["default_overrides"] = dict(default_overrides)
            patched.append("default_overrides")

        if len(updates) > 0:
            draft = draft.model_copy(update=updates)
        job.draft = self._enrich_draft(tenant_id=tenant_id, job=job, draft=draft)
        self._store.save(tenant_id=tenant_id, job=job)
        open_unknowns = list_of_dicts(job.draft.model_dump().get("open_unknowns"))
        return DraftPatchResult(
            draft=job.draft,
            patched_fields=tuple(patched),
            remaining_unknowns_count=len(open_unknowns),
        )

    async def _preview_for_loaded_job(self, *, tenant_id: str, job: Job) -> Draft:
        logger.info("SS_DRAFT_PREVIEW_START", extra={"tenant_id": tenant_id, "job_id": job.job_id})
        prompt = self._draft_preview_prompt(tenant_id=tenant_id, job=job)
        try:
            draft = await self._llm.draft_preview(job=job, prompt=prompt)
        except (LLMCallFailedError, LLMArtifactsWriteError) as e:
            logger.warning(
                "SS_DRAFT_PREVIEW_LLM_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job.job_id,
                    "error_code": e.error_code,
                    "error_message": e.message,
                },
            )
            try:
                self._store.save(tenant_id=tenant_id, job=job)
            except JobStoreIOError as persist_error:
                logger.warning(
                    "SS_DRAFT_PREVIEW_PERSIST_FAILED",
                    extra={
                        "tenant_id": tenant_id,
                        "job_id": job.job_id,
                        "error_code": persist_error.error_code,
                        "error_message": persist_error.message,
                    },
                )
            raise
        draft, _parsed = apply_structured_fields_from_llm_text(draft=draft)
        job.draft = self._enrich_draft(tenant_id=tenant_id, job=job, draft=draft)
        if job.status == JobStatus.CREATED and self._state_machine.ensure_transition(
            job_id=job.job_id,
            from_status=job.status,
            to_status=JobStatus.DRAFT_READY,
        ):
            job.status = JobStatus.DRAFT_READY
        self._store.save(tenant_id=tenant_id, job=job)
        logger.info(
            "SS_DRAFT_PREVIEW_DONE",
            extra={"tenant_id": tenant_id, "job_id": job.job_id, "status": job.status.value},
        )
        return job.draft

    def _draft_preview_prompt(self, *, tenant_id: str, job: Job) -> str:
        requirement = job.requirement if job.requirement is not None else ""
        column_candidates, _ = self._primary_dataset_columns(tenant_id=tenant_id, job_id=job.job_id)
        return build_draft_preview_prompt(
            requirement=requirement,
            column_candidates=column_candidates,
        )

    def _enrich_draft(self, *, tenant_id: str, job: Job, draft: Draft) -> Draft:
        sources = self._data_sources(tenant_id=tenant_id, job_id=job.job_id)
        candidates, types = self._primary_dataset_columns(tenant_id=tenant_id, job_id=job.job_id)
        v1_fields = v1_contract_fields(job=job, draft=draft, candidates=candidates)
        return draft.model_copy(
            update={
                "data_sources": sources,
                "column_candidates": candidates,
                "variable_types": types,
                **v1_fields,
            }
        )

    def _data_sources(self, *, tenant_id: str, job_id: str) -> list[DraftDataSource]:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if job.inputs is None or job.inputs.manifest_rel_path is None:
            return []
        rel_path = job.inputs.manifest_rel_path
        if rel_path.strip() == "":
            return []
        try:
            manifest_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=rel_path,
            )
            manifest = read_manifest_json(manifest_path)
        except (FileNotFoundError, OSError, JSONDecodeError, InputPathUnsafeError, ValueError) as e:
            logger.warning(
                "SS_DRAFT_PREVIEW_INPUTS_MANIFEST_READ_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "rel_path": rel_path,
                    "reason": str(e),
                },
            )
            return []
        datasets = manifest.get("datasets", [])
        if not isinstance(datasets, list):
            return []
        sources: list[DraftDataSource] = []
        for item in datasets:
            if not isinstance(item, dict):
                continue
            dataset_key = item.get("dataset_key")
            role = item.get("role")
            original_name = item.get("original_name")
            fmt = item.get("format")
            if (
                isinstance(dataset_key, str)
                and isinstance(role, str)
                and isinstance(original_name, str)
                and isinstance(fmt, str)
            ):
                sources.append(
                    DraftDataSource(
                        dataset_key=dataset_key,
                        role=role,
                        original_name=original_name,
                        format=fmt,
                    )
                )
        return sources

    def _primary_dataset_columns(
        self, *, tenant_id: str, job_id: str
    ) -> tuple[list[str], list[DraftVariableType]]:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if job.inputs is None or job.inputs.manifest_rel_path is None:
            return [], []
        rel_path = job.inputs.manifest_rel_path
        if rel_path.strip() == "":
            return [], []
        try:
            manifest_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=rel_path,
            )
            manifest = read_manifest_json(manifest_path)
            dataset_rel_path, fmt, _original_name = primary_dataset_details(manifest)
            dataset_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=dataset_rel_path,
            )
            preview = dataset_preview(path=dataset_path, fmt=fmt, rows=1, columns=300)
        except (FileNotFoundError, OSError, JSONDecodeError, InputPathUnsafeError, ValueError) as e:
            logger.warning(
                "SS_DRAFT_PREVIEW_DATASET_PREVIEW_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "rel_path": rel_path,
                    "reason": str(e),
                },
            )
            return [], []
        payload = preview.get("columns", [])
        if not isinstance(payload, list):
            return [], []
        candidates: list[str] = []
        types: list[DraftVariableType] = []
        for item in payload:
            if not isinstance(item, dict):
                continue
            name = item.get("name")
            inferred_type = item.get("inferred_type")
            if not isinstance(name, str) or name.strip() == "":
                continue
            candidates.append(name)
            if isinstance(inferred_type, str) and inferred_type.strip() != "":
                types.append(DraftVariableType(name=name, inferred_type=inferred_type))
        return candidates[:300], types[:300]
