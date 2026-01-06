from __future__ import annotations

import logging

from src.domain.llm_client import LLMClient
from src.domain.models import Draft
from src.infra.job_store import JobStore

logger = logging.getLogger(__name__)


class DraftService:
    """Draft preview service: load job → call LLM → persist → return."""

    def __init__(self, *, store: JobStore, llm: LLMClient):
        self._store = store
        self._llm = llm

    async def preview(self, *, job_id: str) -> Draft:
        logger.info("SS_DRAFT_PREVIEW_START", extra={"job_id": job_id})
        job = self._store.load(job_id)
        prompt = (job.requirement or "").strip()
        draft = await self._llm.draft_preview(job=job, prompt=prompt)
        self._store.write_draft(job_id=job_id, draft=draft)
        logger.info("SS_DRAFT_PREVIEW_DONE", extra={"job_id": job_id})
        return draft
