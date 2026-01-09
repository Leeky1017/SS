from __future__ import annotations

import logging
from json import JSONDecodeError

from src.domain.dataset_preview import dataset_preview
from src.domain.inputs_manifest import primary_dataset_details, read_manifest_json
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient
from src.domain.models import Draft, DraftDataSource, DraftVariableType, JobStatus
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import JobStoreIOError, LLMArtifactsWriteError, LLMCallFailedError
from src.infra.input_exceptions import InputPathUnsafeError
from src.utils.tenancy import DEFAULT_TENANT_ID

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
        logger.info("SS_DRAFT_PREVIEW_START", extra={"tenant_id": tenant_id, "job_id": job_id})
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        requirement = job.requirement if job.requirement is not None else ""
        prompt = requirement.strip()
        try:
            draft = await self._llm.draft_preview(job=job, prompt=prompt)
        except (LLMCallFailedError, LLMArtifactsWriteError) as e:
            logger.warning(
                "SS_DRAFT_PREVIEW_LLM_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
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
                        "job_id": job_id,
                        "error_code": persist_error.error_code,
                        "error_message": persist_error.message,
                    },
                )
            raise
        job.draft = self._enrich_draft(tenant_id=tenant_id, job_id=job_id, draft=draft)
        if job.status == JobStatus.CREATED and self._state_machine.ensure_transition(
            job_id=job_id,
            from_status=job.status,
            to_status=JobStatus.DRAFT_READY,
        ):
            job.status = JobStatus.DRAFT_READY
        self._store.save(tenant_id=tenant_id, job=job)
        logger.info(
            "SS_DRAFT_PREVIEW_DONE",
            extra={"tenant_id": tenant_id, "job_id": job_id, "status": job.status.value},
        )
        return job.draft

    def _enrich_draft(self, *, tenant_id: str, job_id: str, draft: Draft) -> Draft:
        sources = self._data_sources(tenant_id=tenant_id, job_id=job_id)
        candidates, types = self._primary_dataset_columns(tenant_id=tenant_id, job_id=job_id)
        return draft.model_copy(
            update={
                "data_sources": sources,
                "column_candidates": candidates,
                "variable_types": types,
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
