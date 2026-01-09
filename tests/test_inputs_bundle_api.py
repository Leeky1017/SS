from __future__ import annotations

from pathlib import Path

import pytest

from src.api import deps
from src.domain.upload_bundle_service import UploadBundleService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _bundle_service(*, jobs_dir: Path) -> UploadBundleService:
    return UploadBundleService(
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
        max_bundle_files=64,
    )


async def test_post_bundle_allows_duplicate_filenames_and_get_is_stable(
    job_service,
    store,
    jobs_dir,
):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_upload_bundle_service] = async_override(
        _bundle_service(jobs_dir=jobs_dir)
    )

    job = job_service.create_job(tenant_id="tenant-a", requirement="hello")

    payload = {
        "files": [
            {
                "filename": "data.csv",
                "size_bytes": 10,
                "role": "primary_dataset",
                "mime_type": "text/csv",
            },
            {
                "filename": "data.csv",
                "size_bytes": 20,
                "role": "secondary_dataset",
                "mime_type": "text/csv",
            },
            {"filename": "notes.xlsx", "size_bytes": 30, "role": "other", "mime_type": None},
        ]
    }

    async with asgi_client(app=app) as client:
        created = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            json=payload,
            headers={"X-SS-Tenant-ID": "tenant-a"},
        )
    assert created.status_code == 200
    created_payload = created.json()
    assert created_payload["job_id"] == job.job_id
    assert created_payload["bundle_id"].startswith("bundle_")
    assert len(created_payload["files"]) == 3
    assert [f["filename"] for f in created_payload["files"]].count("data.csv") == 2
    assert len({f["file_id"] for f in created_payload["files"]}) == 3

    async with asgi_client(app=app) as client:
        fetched = await client.get(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            headers={"X-SS-Tenant-ID": "tenant-a"},
        )
    assert fetched.status_code == 200
    assert fetched.json() == created_payload


async def test_get_bundle_when_missing_returns_404(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_upload_bundle_service] = async_override(
        _bundle_service(jobs_dir=jobs_dir)
    )

    job = job_service.create_job(tenant_id="tenant-a", requirement="hello")

    async with asgi_client(app=app) as client:
        fetched = await client.get(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            headers={"X-SS-Tenant-ID": "tenant-a"},
        )

    assert fetched.status_code == 404
    assert fetched.json()["error_code"] == "BUNDLE_NOT_FOUND"


async def test_post_bundle_with_unsafe_filename_returns_400(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_upload_bundle_service] = async_override(
        _bundle_service(jobs_dir=jobs_dir)
    )

    job = job_service.create_job(tenant_id="tenant-a", requirement="hello")

    async with asgi_client(app=app) as client:
        created = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            json={
                "files": [
                    {
                        "filename": "../data.csv",
                        "size_bytes": 10,
                        "role": "primary_dataset",
                        "mime_type": None,
                    },
                ]
            },
            headers={"X-SS-Tenant-ID": "tenant-a"},
        )

    assert created.status_code == 400
    assert created.json()["error_code"] == "INPUT_FILENAME_UNSAFE"


async def test_post_bundle_when_primary_missing_returns_400(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_upload_bundle_service] = async_override(
        _bundle_service(jobs_dir=jobs_dir)
    )

    job = job_service.create_job(tenant_id="tenant-a", requirement="hello")

    async with asgi_client(app=app) as client:
        created = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            json={
                "files": [
                    {
                        "filename": "data.csv",
                        "size_bytes": 10,
                        "role": "secondary_dataset",
                        "mime_type": None,
                    },
                ]
            },
            headers={"X-SS-Tenant-ID": "tenant-a"},
        )

    assert created.status_code == 400
    assert created.json()["error_code"] == "INPUT_PRIMARY_DATASET_MISSING"


async def test_get_bundle_when_cross_tenant_access_returns_404(
    job_service,
    store,
    jobs_dir,
) -> None:
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_upload_bundle_service] = async_override(
        _bundle_service(jobs_dir=jobs_dir)
    )

    job = job_service.create_job(tenant_id="tenant-a", requirement="hello")

    async with asgi_client(app=app) as client:
        created = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            json={
                "files": [
                    {
                        "filename": "data.csv",
                        "size_bytes": 10,
                        "role": "primary_dataset",
                        "mime_type": None,
                    },
                ]
            },
            headers={"X-SS-Tenant-ID": "tenant-a"},
        )
    assert created.status_code == 200

    async with asgi_client(app=app) as client:
        fetched = await client.get(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            headers={"X-SS-Tenant-ID": "tenant-b"},
        )

    assert fetched.status_code == 404
    assert fetched.json()["error_code"] == "JOB_NOT_FOUND"
