from __future__ import annotations

import hashlib
import json
from dataclasses import replace
from pathlib import Path

import pytest

from src.api import deps
from src.config import Config, load_config
from src.domain.job_inputs_service import JobInputsService
from src.domain.task_code_redeem_service import TaskCodeRedeemService
from src.domain.upload_bundle_service import UploadBundleService
from src.domain.upload_sessions_service import UploadSessionsService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_upload_session_store import FileUploadSessionStore
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir
from src.utils.time import utc_now
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
        upload_presigned_url_ttl_seconds=900,
        upload_max_file_size_bytes=10_000_000,
        upload_max_sessions_per_job=128,
        upload_multipart_threshold_bytes=16,
        upload_multipart_min_part_size_bytes=4,
        upload_multipart_part_size_bytes=5,
        upload_multipart_max_part_size_bytes=8,
        upload_multipart_max_parts=1000,
        upload_max_bundle_files=64,
    )


def _app(
    *,
    store,
    jobs_dir: Path,
    object_store: FakeObjectStore,
    config: Config,
) -> object:
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
        object_store=object_store,
        bundle_service=upload_bundle,
        session_store=FileUploadSessionStore(jobs_dir=jobs_dir),
    )
    inputs_service = JobInputsService(store=store, workspace=workspace)
    task_codes = TaskCodeRedeemService(store=store, now=utc_now)

    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_job_workspace_store] = async_override(workspace)
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(inputs_service)
    app.dependency_overrides[deps.get_upload_bundle_service] = async_override(upload_bundle)
    app.dependency_overrides[deps.get_upload_sessions_service] = async_override(upload_sessions)
    app.dependency_overrides[deps.get_task_code_redeem_service] = async_override(task_codes)
    app.dependency_overrides[deps.get_config] = async_override(config)
    return app


async def test_upload_sessions_direct_finalize_updates_manifest_and_preview_works(
    job_service,
    store,
    jobs_dir: Path,
) -> None:
    fake = FakeObjectStore()
    app = _app(
        store=store,
        jobs_dir=jobs_dir,
        object_store=fake,
        config=_test_config(jobs_dir=jobs_dir),
    )
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
    file_id = bundle_payload["files"][0]["file_id"]
    bundle_id = bundle_payload["bundle_id"]

    async with asgi_client(app=app) as client:
        session = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/upload-sessions",
            json={"bundle_id": bundle_id, "file_id": file_id},
        )
    assert session.status_code == 200
    session_payload = session.json()
    assert session_payload["upload_strategy"] == "direct"
    assert session_payload["presigned_url"].startswith("fake://")

    etag = fake.put_via_presigned_url(url=session_payload["presigned_url"], data=data)

    async with asgi_client(app=app) as client:
        finalized = await client.post(
            f"/v1/upload-sessions/{session_payload['upload_session_id']}/finalize",
            json={"parts": [{"part_number": 1, "etag": etag, "sha256": _sha256_hex(data)}]},
        )
        preview = await client.get(f"/v1/jobs/{job.job_id}/inputs/preview")

    assert finalized.status_code == 200
    finalized_payload = finalized.json()
    assert finalized_payload["success"] is True
    assert finalized_payload["file_id"] == file_id
    assert finalized_payload["sha256"] == _sha256_hex(data)

    assert preview.status_code == 200
    assert [c["name"] for c in preview.json()["columns"]] == ["a", "b"]

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    manifest = json.loads((job_dir / "inputs" / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["schema_version"] == 2
    assert len(manifest["datasets"]) == 1


async def test_upload_sessions_multipart_refresh_subset_and_finalize_is_supported(
    job_service,
    store,
    jobs_dir: Path,
) -> None:
    fake = FakeObjectStore()
    app = _app(
        store=store,
        jobs_dir=jobs_dir,
        object_store=fake,
        config=_test_config(jobs_dir=jobs_dir),
    )
    job = job_service.create_job(requirement="hello")
    data = b"a,b\n" + b"1,2\n" * 8

    async with asgi_client(app=app) as client:
        bundle = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/bundle",
            json={
                "files": [
                    {
                        "filename": "big.csv",
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
    assert session_payload["upload_strategy"] == "multipart"
    part_size = session_payload["part_size"]
    urls = session_payload["presigned_urls"]
    assert isinstance(urls, list) and len(urls) >= 2

    etags: dict[int, str] = {}
    for item in urls:
        n = int(item["part_number"])
        start = (n - 1) * part_size
        chunk = data[start : start + part_size]
        if chunk == b"":
            break
        etags[n] = fake.put_via_presigned_url(url=item["url"], data=chunk)

    async with asgi_client(app=app) as client:
        refreshed = await client.post(
            f"/v1/upload-sessions/{session_payload['upload_session_id']}/refresh-urls",
            json={"part_numbers": [2]},
        )
    assert refreshed.status_code == 200
    refreshed_payload = refreshed.json()
    assert len(refreshed_payload["parts"]) == 1
    assert refreshed_payload["parts"][0]["part_number"] == 2

    async with asgi_client(app=app) as client:
        finalized = await client.post(
            f"/v1/upload-sessions/{session_payload['upload_session_id']}/finalize",
            json={
                "parts": [{"part_number": n, "etag": etags[n]} for n in sorted(etags.keys())],
            },
        )
    assert finalized.status_code == 200
    payload = finalized.json()
    assert payload["success"] is True
    assert payload["file_id"] == file_id


async def test_upload_sessions_when_job_tc_missing_token_blocks_create_and_refresh(
    store,
    jobs_dir: Path,
) -> None:
    fake = FakeObjectStore()
    app = _app(
        store=store,
        jobs_dir=jobs_dir,
        object_store=fake,
        config=_test_config(jobs_dir=jobs_dir),
    )

    async with asgi_client(app=app) as client:
        redeemed = await client.post(
            "/v1/task-codes/redeem",
            json={"task_code": "tc-238-upload", "requirement": "hello"},
        )
    assert redeemed.status_code == 200
    job_id = redeemed.json()["job_id"]
    token = redeemed.json()["token"]

    async with asgi_client(app=app) as client:
        bundle = await client.post(
            f"/v1/jobs/{job_id}/inputs/bundle",
            json={
                "files": [
                    {
                        "filename": "data.csv",
                        "size_bytes": 12,
                        "role": "primary_dataset",
                        "mime_type": "text/csv",
                    }
                ]
            },
            headers={"Authorization": f"Bearer {token}"},
        )
    assert bundle.status_code == 200
    file_id = bundle.json()["files"][0]["file_id"]
    bundle_id = bundle.json()["bundle_id"]

    async with asgi_client(app=app) as client:
        missing_token = await client.post(
            f"/v1/jobs/{job_id}/inputs/upload-sessions",
            json={"bundle_id": bundle_id, "file_id": file_id},
        )
    assert missing_token.status_code == 401

    async with asgi_client(app=app) as client:
        ok = await client.post(
            f"/v1/jobs/{job_id}/inputs/upload-sessions",
            json={"bundle_id": bundle_id, "file_id": file_id},
            headers={"Authorization": f"Bearer {token}"},
        )
    assert ok.status_code == 200
    upload_session_id = ok.json()["upload_session_id"]

    async with asgi_client(app=app) as client:
        refresh_missing = await client.post(
            f"/v1/upload-sessions/{upload_session_id}/refresh-urls",
            json={"part_numbers": [1]},
        )
    assert refresh_missing.status_code == 401
