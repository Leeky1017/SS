from __future__ import annotations

import pytest

from src.api import deps
from src.domain.job_inputs_service import JobInputsService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _app(*, job_inputs_service: JobInputsService, draft_service):  # noqa: ANN001
    app = create_app()
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(job_inputs_service)
    app.dependency_overrides[deps.get_draft_service] = async_override(draft_service)
    return app


async def test_draft_preview_includes_auxiliary_columns_in_candidates_v2(
    job_service, store, jobs_dir, draft_service
) -> None:
    job = job_service.create_job(requirement="hello")
    job_inputs_service = JobInputsService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )
    app = _app(job_inputs_service=job_inputs_service, draft_service=draft_service)

    async with asgi_client(app=app) as client:
        uploaded = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/upload",
            files=[
                ("file", ("main.csv", b"a,b\n1,2\n", "text/csv")),
                ("file", ("aux.csv", b"x,y\n3,4\n", "text/csv")),
            ],
            data={"role": ["primary_dataset", "auxiliary_data"]},
        )
        assert uploaded.status_code == 200

        preview = await client.get(f"/v1/jobs/{job.job_id}/draft/preview")
        assert preview.status_code == 200
        payload = preview.json()

    assert payload["status"] == "ready"
    assert set(payload["column_candidates"]) >= {"a", "b", "x", "y"}

    v2 = payload["column_candidates_v2"]
    assert any(item["role"] == "primary_dataset" and item["name"] == "a" for item in v2)
    assert any(item["role"] == "primary_dataset" and item["name"] == "b" for item in v2)
    assert any(item["role"] == "auxiliary_data" and item["name"] == "x" for item in v2)
    assert any(item["role"] == "auxiliary_data" and item["name"] == "y" for item in v2)
    assert all(
        isinstance(item.get("dataset_key"), str) and item["dataset_key"].strip() != ""
        for item in v2
    )
