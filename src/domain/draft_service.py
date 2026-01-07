from __future__ import annotations

import logging

from src.domain.job_store import JobStore
from src.domain.llm_client import LLMClient
from src.domain.models import Draft, JobStatus
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import JobStoreIOError, LLMArtifactsWriteError, LLMCallFailedError

logger = logging.getLogger(__name__)


class DraftService:
    """Draft preview service: load job → call LLM → persist → return."""

    def __init__(self, *, store: JobStore, llm: LLMClient, state_machine: JobStateMachine):
        self._store = store
        self._llm = llm
        self._state_machine = state_machine

    async def preview(self, *, job_id: str) -> Draft:
        logger.info("SS_DRAFT_PREVIEW_START", extra={"job_id": job_id})
        job = self._store.load(job_id)
        requirement = job.requirement if job.requirement is not None else ""
        prompt = requirement.strip()
        try:
            draft = await self._llm.draft_preview(job=job, prompt=prompt)
        except (LLMCallFailedError, LLMArtifactsWriteError) as e:
            logger.warning(
                "SS_DRAFT_PREVIEW_LLM_FAILED",
                extra={"job_id": job_id, "error_code": e.error_code, "error_message": e.message},
            )
            try:
                self._store.save(job)
            except JobStoreIOError as persist_error:
                logger.warning(
                    "SS_DRAFT_PREVIEW_PERSIST_FAILED",
                    extra={
                        "job_id": job_id,
                        "error_code": persist_error.error_code,
                        "error_message": persist_error.message,
                    },
                )
            raise
        job.draft = draft
        if job.status == JobStatus.CREATED and self._state_machine.ensure_transition(
            job_id=job_id,
            from_status=job.status,
            to_status=JobStatus.DRAFT_READY,
        ):
            job.status = JobStatus.DRAFT_READY
        self._store.save(job)
        logger.info("SS_DRAFT_PREVIEW_DONE", extra={"job_id": job_id, "status": job.status.value})
        return draft
