from __future__ import annotations

from src.domain.models import Draft, Job


class LLMProviderError(Exception):
    """Raised by LLM adapters when the provider fails."""


class LLMClient:
    """LLM client entrypoint used by domain services."""

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        draft = await self.draft_preview(job=job, prompt=prompt)
        return draft.text

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        raise NotImplementedError
