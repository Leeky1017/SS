from __future__ import annotations

import logging
from typing import cast

from src.domain.do_template_selection_service import DoTemplateSelectionService
from src.domain.draft_column_candidates_v2 import column_candidates_v2
from src.domain.draft_inputs_introspection import draft_data_sources, primary_dataset_columns
from src.domain.draft_preview_llm import (
    DraftPreviewParseError,
    apply_structured_fields_from_llm_text,
    build_draft_preview_prompt_v2,
)
from src.domain.draft_v1_contract import (
    DraftPatchResult,
    DraftPreviewResult,
    has_inputs,
    is_v1_redeem_job,
    pending_inputs_upload_result,
    v1_contract_fields,
)
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient
from src.domain.models import ArtifactKind, Draft, DraftColumnCandidateV2, Job, JobStatus
from src.domain.state_machine import JobStateMachine
from src.infra.do_template_selection_exceptions import DoTemplateSelectionNotWiredError
from src.infra.exceptions import JobStoreIOError, LLMArtifactsWriteError, LLMCallFailedError
from src.infra.job_lock_exceptions import JobLockedError
from src.infra.llm_output_exceptions import LLMResponseInvalidError
from src.utils.json_types import JsonValue
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)

def _merge_column_candidates(
    primary: list[str], v2: list[DraftColumnCandidateV2]
) -> list[str]:
    out = list(primary)
    seen = {name for name in out if name.strip() != ""}
    for item in v2:
        name = item.name
        if name.strip() == "" or name in seen:
            continue
        out.append(name)
        seen.add(name)
        if len(out) >= 300:
            break
    return out[:300]


class DraftService:
    """Draft preview service: load job → call LLM → persist → return."""

    def __init__(
        self,
        *,
        store: JobStore,
        llm: LLMClient,
        state_machine: JobStateMachine,
        workspace: JobWorkspaceStore,
        do_template_selection: DoTemplateSelectionService | None = None,
    ):
        self._store = store
        self._llm = llm
        self._state_machine = state_machine
        self._workspace = workspace
        self._do_template_selection = do_template_selection

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
        if is_v1_redeem_job(job_id):
            selector = self._do_template_selection
            if selector is None:
                logger.warning(
                    "SS_DRAFT_PREVIEW_DO_TEMPLATE_SELECTION_NOT_WIRED",
                    extra={"tenant_id": tenant_id, "job_id": job_id},
                )
                raise DoTemplateSelectionNotWiredError()
            await selector.select_template_id(tenant_id=tenant_id, job_id=job_id)
        return DraftPreviewResult(draft=draft, pending=None)
    def patch_v1(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        field_updates: dict[str, JsonValue],
    ) -> DraftPatchResult:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if job.status in {
            JobStatus.CONFIRMED, JobStatus.QUEUED, JobStatus.RUNNING,
            JobStatus.SUCCEEDED, JobStatus.FAILED,
        }:
            raise JobLockedError(job_id=job_id, status=job.status.value, operation="draft.patch")
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
        return DraftPatchResult(
            draft=job.draft,
            patched_fields=tuple(patched),
            remaining_unknowns_count=len(job.draft.open_unknowns),
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
        try:
            draft, _parsed = apply_structured_fields_from_llm_text(draft=draft, strict=True)
        except DraftPreviewParseError as e:
            llm_call_id = None
            for ref in reversed(job.artifacts_index):
                if ref.kind == ArtifactKind.LLM_META:
                    parts = ref.rel_path.split("/")
                    if len(parts) >= 3:
                        llm_call_id = parts[-2]
                    break
            logger.warning(
                "SS_DRAFT_PREVIEW_LLM_RESPONSE_INVALID",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job.job_id,
                    "llm_call_id": llm_call_id,
                    "reason": str(e),
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
            raise LLMResponseInvalidError(job_id=job.job_id) from e
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
        primary_candidates, _types = primary_dataset_columns(
            tenant_id=tenant_id,
            job_id=job.job_id,
            store=self._store,
            workspace=self._workspace,
        )
        candidates_v2 = column_candidates_v2(
            tenant_id=tenant_id,
            job_id=job.job_id,
            store=self._store,
            workspace=self._workspace,
            primary_candidates=primary_candidates,
        )
        merged_candidates = _merge_column_candidates(primary_candidates, candidates_v2)
        return build_draft_preview_prompt_v2(
            requirement=requirement,
            column_candidates=merged_candidates,
        )

    def _enrich_draft(self, *, tenant_id: str, job: Job, draft: Draft) -> Draft:
        sources = draft_data_sources(
            tenant_id=tenant_id,
            job_id=job.job_id,
            store=self._store,
            workspace=self._workspace,
        )
        primary_candidates, types = primary_dataset_columns(
            tenant_id=tenant_id,
            job_id=job.job_id,
            store=self._store,
            workspace=self._workspace,
        )
        candidates_v2 = column_candidates_v2(
            tenant_id=tenant_id,
            job_id=job.job_id,
            store=self._store,
            workspace=self._workspace,
            primary_candidates=primary_candidates,
        )
        merged_candidates = _merge_column_candidates(primary_candidates, candidates_v2)
        v1_fields = v1_contract_fields(job=job, draft=draft, candidates=merged_candidates)
        return draft.model_copy(
            update={
                "data_sources": sources,
                "column_candidates": merged_candidates,
                "column_candidates_v2": candidates_v2,
                "variable_types": types,
                **v1_fields,
            }
        )
