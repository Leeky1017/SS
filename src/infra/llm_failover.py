from __future__ import annotations

import asyncio
import logging

from src.domain.llm_client import LLMClient, LLMProviderError
from src.domain.models import Draft, Job

logger = logging.getLogger(__name__)


class FailoverLLMClient(LLMClient):
    """LLM adapter that falls back when the primary is unavailable."""

    def __init__(
        self,
        *,
        primary: LLMClient,
        fallback: LLMClient,
        primary_timeout_seconds: float,
    ):
        self._primary = primary
        self._fallback = fallback
        self._primary_timeout_seconds = max(0.0, float(primary_timeout_seconds))

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        try:
            return await asyncio.wait_for(
                self._primary.complete_text(job=job, operation=operation, prompt=prompt),
                timeout=self._primary_timeout_seconds,
            )
        except asyncio.TimeoutError:
            logger.warning(
                "SS_LLM_FAILOVER_PRIMARY_TIMEOUT",
                extra={"job_id": job.job_id, "timeout_seconds": self._primary_timeout_seconds},
            )
        except LLMProviderError:
            logger.warning(
                "SS_LLM_FAILOVER_PRIMARY_ERROR",
                extra={"job_id": job.job_id, "error_type": "LLMProviderError"},
            )

        logger.info("SS_LLM_FAILOVER_USED", extra={"job_id": job.job_id})
        return await self._fallback.complete_text(job=job, operation=operation, prompt=prompt)

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        try:
            return await asyncio.wait_for(
                self._primary.draft_preview(job=job, prompt=prompt),
                timeout=self._primary_timeout_seconds,
            )
        except asyncio.TimeoutError:
            logger.warning(
                "SS_LLM_FAILOVER_PRIMARY_TIMEOUT",
                extra={"job_id": job.job_id, "timeout_seconds": self._primary_timeout_seconds},
            )
        except LLMProviderError as e:
            logger.warning(
                "SS_LLM_FAILOVER_PRIMARY_ERROR",
                extra={"job_id": job.job_id, "error_type": type(e).__name__},
            )

        logger.info("SS_LLM_FAILOVER_USED", extra={"job_id": job.job_id})
        return await self._fallback.draft_preview(job=job, prompt=prompt)
