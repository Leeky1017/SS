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


async def test_draft_preview_includes_required_variables_for_id_time(
    job_service, store, jobs_dir, draft_service
) -> None:
    job = job_service.create_job(requirement="hello")
    job_inputs_service = JobInputsService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )
    app = _app(job_inputs_service=job_inputs_service, draft_service=draft_service)

    csv_bytes = b"id,year,y\n1,2000,3\n"
    async with asgi_client(app=app) as client:
        uploaded = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/upload",
            files=[("file", ("main.csv", csv_bytes, "text/csv"))],
            data={"role": ["primary_dataset"]},
        )
        assert uploaded.status_code == 200

        preview = await client.get(f"/v1/jobs/{job.job_id}/draft/preview")
        assert preview.status_code == 200
        payload = preview.json()

    required = payload["required_variables"]
    assert isinstance(required, list)
    id_item = next(item for item in required if item.get("field") == "__ID_VAR__")
    time_item = next(item for item in required if item.get("field") == "__TIME_VAR__")
    assert "id" in id_item.get("candidates", [])
    assert "year" in time_item.get("candidates", [])
