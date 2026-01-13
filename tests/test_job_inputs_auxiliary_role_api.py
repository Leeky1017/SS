from __future__ import annotations

import json

import pytest

from src.api import deps
from src.domain.job_inputs_service import JobInputsService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _svc(*, store, jobs_dir) -> JobInputsService:
    return JobInputsService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir))


def _app(*, svc: JobInputsService):
    app = create_app()
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(svc)
    return app


async def test_upload_primary_and_auxiliary_datasets_records_roles(
    job_service, store, jobs_dir
) -> None:
    # Arrange
    job = job_service.create_job(requirement="hello")
    app = _app(svc=_svc(store=store, jobs_dir=jobs_dir))

    # Act
    async with asgi_client(app=app) as client:
        uploaded = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/upload",
            files=[
                ("file", ("main.csv", b"a,b\n1,2\n", "text/csv")),
                ("file", ("aux.csv", b"x,y\n3,4\n", "text/csv")),
            ],
            data={"role": ["primary_dataset", "auxiliary_data"]},
        )

    # Assert
    assert uploaded.status_code == 200
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    manifest = json.loads((job_dir / "inputs" / "manifest.json").read_text(encoding="utf-8"))
    roles = sorted([d["role"] for d in manifest["datasets"]])
    assert roles == ["auxiliary_data", "primary_dataset"]
