from __future__ import annotations

import asyncio
import logging

import pytest

from src.api import deps
from src.domain.draft_service import DraftService
from src.domain.llm_client import LLMClient, StubLLMClient
from src.domain.models import Draft, Job
from src.domain.state_machine import JobStateMachine
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.job_store import JobStore
from src.infra.llm_failover import FailoverLLMClient
from src.infra.llm_tracing import TracedLLMClient
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override


@pytest.mark.anyio
async def test_draft_preview_when_llm_times_out_uses_fallback(
    job_service,
    store: JobStore,
    jobs_dir,
    state_machine: JobStateMachine,
    caplog,
) -> None:
    class SlowLLMClient(LLMClient):
        async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
            await asyncio.sleep(3600)
            return Draft(text="unexpected", created_at="never")

    llm = TracedLLMClient(
        inner=FailoverLLMClient(
            primary=SlowLLMClient(),
            fallback=StubLLMClient(),
            primary_timeout_seconds=0.05,
        ),
        jobs_dir=jobs_dir,
        model="fake",
        temperature=None,
        seed=None,
        timeout_seconds=30.0,
        max_attempts=1,
        retry_backoff_base_seconds=0.0,
        retry_backoff_max_seconds=0.0,
    )
    draft_service = DraftService(
        store=store,
        llm=llm,
        state_machine=state_machine,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_draft_service] = async_override(draft_service)

    job = job_service.create_job(requirement="hello")

    with caplog.at_level(logging.INFO):
        async with asgi_client(app=app) as client:
            response = await client.get(f"/v1/jobs/{job.job_id}/draft/preview")

    assert response.status_code == 200
    assert response.json()["draft_text"].startswith("[stub-draft:")

    failover_records = [r for r in caplog.records if r.msg == "SS_LLM_FAILOVER_USED"]
    assert len(failover_records) == 1
    assert failover_records[0].job_id == job.job_id
