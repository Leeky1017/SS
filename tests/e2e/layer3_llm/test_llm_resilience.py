from __future__ import annotations

import httpx
import pytest
from fastapi import FastAPI

from src.api import deps
from src.domain.do_template_selection_service import DoTemplateSelectionService
from src.domain.draft_service import DraftService
from src.domain.llm_client import LLMProviderError
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.llm_tracing import TracedLLMClient
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override
from tests.e2e.fakes.scripted_llm_client import (
    ScriptedLLMClient,
    draft_preview_v2_json,
)
from tests.v1_redeem import redeem_job

pytestmark = pytest.mark.anyio


async def _upload_csv(*, client: httpx.AsyncClient, job_id: str) -> None:
    files = [("file", ("primary.csv", b"id,y,x\n1,2,3\n", "text/csv"))]
    response = await client.post(f"/v1/jobs/{job_id}/inputs/upload", files=files)
    assert response.status_code == 200


def _override_draft_service(
    *,
    app: FastAPI,
    jobs_dir,
    store,
    state_machine,
    workspace: FileJobWorkspaceStore,
    do_template_library_dir,
    inner_llm: ScriptedLLMClient,
) -> None:
    traced = TracedLLMClient(
        inner=inner_llm,
        jobs_dir=jobs_dir,
        model="fake",
        temperature=0.0,
        seed=None,
        timeout_seconds=0.05,
        max_attempts=1,
        retry_backoff_base_seconds=0.0,
        retry_backoff_max_seconds=0.0,
    )
    selection = DoTemplateSelectionService(
        store=store,
        llm=traced,
        catalog=FileSystemDoTemplateCatalog(library_dir=do_template_library_dir),
    )
    draft_service = DraftService(
        store=store,
        llm=traced,
        state_machine=state_machine,
        workspace=workspace,
        do_template_selection=selection,
    )
    app.dependency_overrides[deps.get_draft_service] = async_override(draft_service)


async def test_llm_provider_failure_returns_502_and_job_status_does_not_advance(
    e2e_app: FastAPI,
    e2e_jobs_dir,
    e2e_store,
    e2e_state_machine,
    e2e_job_workspace_store: FileJobWorkspaceStore,
    e2e_do_template_library_dir,
) -> None:
    _override_draft_service(
        app=e2e_app,
        jobs_dir=e2e_jobs_dir,
        store=e2e_store,
        state_machine=e2e_state_machine,
        workspace=e2e_job_workspace_store,
        do_template_library_dir=e2e_do_template_library_dir,
        inner_llm=ScriptedLLMClient(draft_preview_steps=[LLMProviderError("timeout")]),
    )
    async with asgi_client(app=e2e_app) as client:
        job_id, _token = await redeem_job(
            client=client,
            task_code="tc_e2e_llm_provider_fail",
            requirement="req",
        )
        await _upload_csv(client=client, job_id=job_id)

        preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert preview.status_code == 502
        assert preview.json()["error_code"] == "LLM_CALL_FAILED"

        job = await client.get(f"/v1/jobs/{job_id}")
        assert job.status_code == 200
        assert job.json()["status"] == "created"

        inputs = await client.get(f"/v1/jobs/{job_id}/inputs/preview")
        assert inputs.status_code == 200


async def test_llm_failure_then_retry_succeeds_without_reupload(
    e2e_app: FastAPI,
    e2e_jobs_dir,
    e2e_store,
    e2e_state_machine,
    e2e_job_workspace_store: FileJobWorkspaceStore,
    e2e_do_template_library_dir,
) -> None:
    inner = ScriptedLLMClient(
        draft_preview_steps=[
            LLMProviderError("transient"),
            draft_preview_v2_json(draft_text="ok"),
        ]
    )
    _override_draft_service(
        app=e2e_app,
        jobs_dir=e2e_jobs_dir,
        store=e2e_store,
        state_machine=e2e_state_machine,
        workspace=e2e_job_workspace_store,
        do_template_library_dir=e2e_do_template_library_dir,
        inner_llm=inner,
    )
    async with asgi_client(app=e2e_app) as client:
        job_id, _token = await redeem_job(
            client=client,
            task_code="tc_e2e_llm_retry",
            requirement="req",
        )
        await _upload_csv(client=client, job_id=job_id)

        first = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert first.status_code == 502

        second = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert second.status_code == 200
        assert second.json()["draft_text"] == "ok"

        job = await client.get(f"/v1/jobs/{job_id}")
        assert job.status_code == 200
        assert job.json()["status"] == "draft_ready"
