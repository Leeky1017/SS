from __future__ import annotations

import hashlib
from dataclasses import replace
from pathlib import Path

import anyio
import pytest

from src.api import deps
from src.config import Config, load_config
from src.domain.job_inputs_service import JobInputsService
from src.domain.upload_bundle_service import UploadBundleService
from src.domain.upload_sessions_service import UploadSessionsService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_upload_session_store import FileUploadSessionStore
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override
from tests.fakes.fake_object_store import FakeObjectStore

pytestmark = pytest.mark.anyio


def _sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _test_config(*, jobs_dir: Path) -> Config:
    raw = load_config(
        env={
            "SS_LLM_PROVIDER": "yunwu",
            "SS_LLM_API_KEY": "test-key",
            "SS_JOBS_DIR": str(jobs_dir),
        }
    )
    return replace(
        raw,
        jobs_dir=jobs_dir,
        upload_object_store_backend="s3",
        upload_max_sessions_per_job=10_000,
        upload_multipart_threshold_bytes=16,
        upload_multipart_min_part_size_bytes=4,
        upload_multipart_part_size_bytes=5,
        upload_multipart_max_part_size_bytes=8,
        upload_multipart_max_parts=1000,
    )


def _app(*, store, jobs_dir: Path, fake: FakeObjectStore, config: Config):
    app = create_app()
    workspace = FileJobWorkspaceStore(jobs_dir=jobs_dir)
    upload_bundle = UploadBundleService(
        workspace=workspace,
        max_bundle_files=int(config.upload_max_bundle_files),
    )
    upload_sessions = UploadSessionsService(
        config=config,
        store=store,
        workspace=workspace,
        object_store=fake,
        bundle_service=upload_bundle,
        session_store=FileUploadSessionStore(jobs_dir=jobs_dir),
    )
    inputs_service = JobInputsService(store=store, workspace=workspace)
    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_job_workspace_store] = async_override(workspace)
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(inputs_service)
    app.dependency_overrides[deps.get_upload_bundle_service] = async_override(upload_bundle)
    app.dependency_overrides[deps.get_upload_sessions_service] = async_override(upload_sessions)
    app.dependency_overrides[deps.get_config] = async_override(config)
    return app


async def test_upload_sessions_concurrent_create_returns_unique_session_ids(
    job_service, store, jobs_dir: Path
) -> None:
    fake = FakeObjectStore()
    config = _test_config(jobs_dir=jobs_dir)
    app = _app(store=store, jobs_dir=jobs_dir, fake=fake, config=config)
    job = job_service.create_job(requirement="hello")
    data = b"a,b\n1,2\n"

    async with asgi_client(app=app) as client:
        bundle = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            json={
                "files": [
                    {
                        "filename": "data.csv",
                        "size_bytes": len(data),
                        "role": "primary_dataset",
                        "mime_type": "text/csv",
                    }
                ]
            },
        )
    assert bundle.status_code == 200
    bundle_payload = bundle.json()
    bundle_id = bundle_payload["bundle_id"]
    file_id = bundle_payload["files"][0]["file_id"]

    ids: list[str] = []

    async with asgi_client(app=app) as client:
        async def worker() -> None:
            resp = await client.post(
                f"/v1/jobs/{job.job_id}/inputs/upload-sessions",
                json={"bundle_id": bundle_id, "file_id": file_id},
            )
            assert resp.status_code == 200
            ids.append(resp.json()["upload_session_id"])

        async with anyio.create_task_group() as tg:
            for _ in range(25):
                tg.start_soon(worker)

    assert len(ids) == 25
    assert len(set(ids)) == 25


async def test_upload_sessions_concurrent_finalize_returns_consistent_payload(
    job_service, store, jobs_dir: Path
) -> None:
    fake = FakeObjectStore()
    config = _test_config(jobs_dir=jobs_dir)
    app = _app(store=store, jobs_dir=jobs_dir, fake=fake, config=config)
    job = job_service.create_job(requirement="hello")
    data = b"a,b\n1,2\n"

    async with asgi_client(app=app) as client:
        bundle = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            json={
                "files": [
                    {
                        "filename": "data.csv",
                        "size_bytes": len(data),
                        "role": "primary_dataset",
                        "mime_type": "text/csv",
                    }
                ]
            },
        )
        bundle_payload = bundle.json()
        file_id = bundle_payload["files"][0]["file_id"]
        bundle_id = bundle_payload["bundle_id"]
        session = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/upload-sessions",
            json={"bundle_id": bundle_id, "file_id": file_id},
        )
    assert session.status_code == 200
    session_payload = session.json()
    etag = fake.put_via_presigned_url(url=session_payload["presigned_url"], data=data)
    upload_session_id = session_payload["upload_session_id"]

    results: list[dict[str, object]] = []

    async with asgi_client(app=app) as client:
        async def worker() -> None:
            resp = await client.post(
                f"/v1/upload-sessions/{upload_session_id}/finalize",
                json={
                    "parts": [
                        {
                            "part_number": 1,
                            "etag": etag,
                            "sha256": _sha256_hex(data),
                        }
                    ]
                },
            )
            assert resp.status_code == 200
            results.append(resp.json())

        async with anyio.create_task_group() as tg:
            for _ in range(10):
                tg.start_soon(worker)

    assert len(results) == 10
    assert all(r.get("success") is True for r in results)
    assert len({tuple(sorted(r.items())) for r in results}) == 1
