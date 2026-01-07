from __future__ import annotations

import hashlib
import json

from src.domain.models import Draft, Job
from src.utils.time import utc_now


class LLMProviderError(Exception):
    """Raised by LLM adapters when the provider fails."""


class LLMClient:
    """LLM client single entry. Replace `StubLLMClient` with real implementation later."""

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        draft = await self.draft_preview(job=job, prompt=prompt)
        return draft.text

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        raise NotImplementedError


class StubLLMClient(LLMClient):
    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        if operation == "do_template.select_families":
            return self._stub_select_family_ids(prompt)
        if operation == "do_template.select_template":
            return self._stub_select_template_id(prompt)
        draft = await self.draft_preview(job=job, prompt=prompt)
        return draft.text

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        seed = f"{job.job_id}:{prompt}".encode("utf-8", errors="ignore")
        digest = hashlib.sha256(seed).hexdigest()[:12]
        text = f"[stub-draft:{digest}] {prompt or 'No requirement provided.'}"
        return Draft(text=text, created_at=utc_now().isoformat())

    def _stub_select_family_ids(self, prompt: str) -> str:
        family_ids = _first_csv_line_value(prompt, key="CANONICAL_FAMILY_IDS")
        selected = family_ids[:1] if family_ids else ["descriptive"]
        payload = {
            "schema_version": 1,
            "families": [
                {
                    "family_id": selected[0],
                    "reason": "stub selection",
                    "confidence": 0.5,
                }
            ],
        }
        return _json_dumps(payload)

    def _stub_select_template_id(self, prompt: str) -> str:
        ids = _first_csv_line_value(prompt, key="CANDIDATE_TEMPLATE_IDS")
        selected = ids[:1] if ids else ["T01"]
        payload = {
            "schema_version": 1,
            "template_id": selected[0],
            "reason": "stub selection",
            "confidence": 0.5,
        }
        return _json_dumps(payload)


def _first_csv_line_value(text: str, *, key: str) -> list[str]:
    needle = f"{key}:"
    for line in text.splitlines():
        if not line.startswith(needle):
            continue
        raw = line[len(needle) :].strip()
        if raw == "":
            return []
        values = [v.strip() for v in raw.split(",")]
        return [v for v in values if v != ""]
    return []


def _json_dumps(payload: dict[str, object]) -> str:
    return json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
