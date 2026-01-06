from __future__ import annotations

import hashlib

from src.domain.models import Draft, Job
from src.utils.time import utc_now


class LLMClient:
    """LLM client single entry. Replace `StubLLMClient` with real implementation later."""

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        raise NotImplementedError


class StubLLMClient(LLMClient):
    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        seed = f"{job.job_id}:{prompt}".encode("utf-8", errors="ignore")
        digest = hashlib.sha256(seed).hexdigest()[:12]
        text = f"[stub-draft:{digest}] {prompt or 'No requirement provided.'}"
        return Draft(text=text, created_at=utc_now().isoformat())
