from __future__ import annotations

import asyncio
import json

import pytest

from src.domain.draft_service import DraftService
from src.domain.llm_client import LLMClient
from src.domain.models import Draft, Job
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.llm_output_exceptions import LLMResponseInvalidError
from src.utils.time import utc_now


def test_draft_preview_with_json_output_populates_structured_fields(
    job_service,
    store,
    state_machine,
    jobs_dir,
) -> None:
    class JsonLLMClient(LLMClient):
        async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
            payload = {
                "draft_text": "Plan: summarize y, then estimate x effect with controls.",
                "outcome_var": "y",
                "treatment_var": "x",
                "controls": ["c1", "c2"],
                "default_overrides": {"alpha": 0.05},
            }
            return Draft(text=json.dumps(payload), created_at=utc_now().isoformat())

    svc = DraftService(
        store=store,
        llm=JsonLLMClient(),
        state_machine=state_machine,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    job = job_service.create_job(requirement="estimate x on y with c1 c2")

    draft = asyncio.run(svc.preview(job_id=job.job_id))
    assert draft.text == "Plan: summarize y, then estimate x effect with controls."
    assert draft.outcome_var == "y"
    assert draft.treatment_var == "x"
    assert draft.controls == ["c1", "c2"]
    assert draft.default_overrides == {"alpha": 0.05}

    loaded = store.load(job.job_id)
    assert loaded.draft is not None
    assert loaded.draft.outcome_var == "y"


def test_draft_preview_with_non_json_output_raises_llm_response_invalid_error(
    job_service,
    store,
    state_machine,
    jobs_dir,
) -> None:
    class TextLLMClient(LLMClient):
        async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
            return Draft(text="plain text draft", created_at=utc_now().isoformat())

    svc = DraftService(
        store=store,
        llm=TextLLMClient(),
        state_machine=state_machine,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    job = job_service.create_job(requirement="hello")

    with pytest.raises(LLMResponseInvalidError):
        asyncio.run(svc.preview(job_id=job.job_id))
    loaded = store.load(job.job_id)
    assert loaded.status.value == "created"
    assert loaded.draft is None
