from __future__ import annotations

import json
from dataclasses import dataclass, field

from src.domain.llm_client import LLMClient
from src.domain.models import Job
from tests.fakes.fake_llm_client import FakeLLMClient


def draft_preview_v2_json(*, draft_text: str) -> str:
    payload = {
        "schema_version": 2,
        "draft_text": draft_text,
        "outcome_var": None,
        "treatment_var": None,
        "controls": [],
        "time_var": None,
        "entity_var": None,
        "cluster_var": None,
        "fixed_effects": [],
        "interaction_terms": [],
        "instrument_var": None,
        "analysis_hints": [],
        "default_overrides": {},
    }
    return json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


@dataclass
class ScriptedLLMClient(LLMClient):
    """Script `draft_preview` responses while keeping template-selection ops valid."""

    draft_preview_steps: list[object] = field(default_factory=list)
    fallback: LLMClient = field(default_factory=FakeLLMClient)

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        if operation == "draft_preview":
            return self._next_draft_preview_text()
        return await self.fallback.complete_text(job=job, operation=operation, prompt=prompt)

    def _next_draft_preview_text(self) -> str:
        if not self.draft_preview_steps:
            return draft_preview_v2_json(draft_text="ok")
        step = self.draft_preview_steps.pop(0)
        if isinstance(step, Exception):
            raise step
        return str(step)

