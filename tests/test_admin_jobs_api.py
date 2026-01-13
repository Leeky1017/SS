from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path

import pytest

from src.api import deps
from src.config import Config, load_config
from src.domain.artifacts_service import ArtifactsService
from src.domain.models import (
    JOB_SCHEMA_VERSION_CURRENT,
    ArtifactKind,
    ArtifactRef,
    Draft,
    Job,
    JobStatus,
    RunAttempt,
)
from src.infra.job_store import JobStore
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _test_config(*, tmp_path: Path) -> Config:
    env = dict(os.environ)
    env["SS_JOBS_DIR"] = str(tmp_path / "jobs")
    env["SS_QUEUE_DIR"] = str(tmp_path / "queue")
    env["SS_ADMIN_DATA_DIR"] = str(tmp_path / "admin")
    env["SS_ADMIN_USERNAME"] = "admin"
    env["SS_ADMIN_PASSWORD"] = "admin"
    return load_config(env)


async def _admin_login(*, client) -> str:
    login = await client.post(
        "/api/admin/auth/login",
        json={"username": "admin", "password": "admin"},
    )
    assert login.status_code == 200
    return str(login.json()["token"])


async def _admin_auth_headers(*, client) -> dict[str, str]:
    token = await _admin_login(client=client)
    return {"Authorization": f"Bearer {token}"}


class _FakeJobService:
    def __init__(self, *, store: JobStore) -> None:
        self._store = store

    def trigger_run(self, *, tenant_id: str, job_id: str) -> Job:
        job = self._store.load(job_id, tenant_id=tenant_id)
        job.status = JobStatus.QUEUED
        job.scheduled_at = datetime.now(timezone.utc).isoformat()
        self._store.save(job, tenant_id=tenant_id)
        return job


def _seed_jobs(*, config: Config, store: JobStore) -> tuple[str, str]:
    job_default = Job(
        schema_version=JOB_SCHEMA_VERSION_CURRENT,
        tenant_id="default",
        job_id="job_admin_default",
        status=JobStatus.FAILED,
        created_at="2026-01-01T00:00:00+00:00",
        requirement="req-default",
        draft=Draft(text="draft-default", created_at="2026-01-01T00:00:01+00:00"),
        runs=[RunAttempt(run_id="run-1", attempt=1, status="failed")],
        artifacts_index=[
            ArtifactRef(
                kind=ArtifactKind.RUN_STDOUT,
                rel_path="outputs/stdout.txt",
                created_at="2026-01-01T00:00:02+00:00",
                meta={"rows": 1, "bad": ["x"], "ok": True},
            )
        ],
    )
    store.create(job_default)

    job_tenant = Job(
        schema_version=JOB_SCHEMA_VERSION_CURRENT,
        tenant_id="tenant-a",
        job_id="job_admin_tenant",
        status=JobStatus.SUCCEEDED,
        created_at="2026-01-02T00:00:00+00:00",
        requirement="req-tenant",
    )
    store.create(job_tenant, tenant_id="tenant-a")

    job_dir = resolve_job_dir(
        jobs_dir=config.jobs_dir,
        tenant_id="default",
        job_id=job_default.job_id,
    )
    assert job_dir is not None
    artifact_path = job_dir / "outputs" / "stdout.txt"
    artifact_path.parent.mkdir(parents=True, exist_ok=True)
    artifact_path.write_text("hello", encoding="utf-8")

    return job_default.job_id, job_tenant.job_id


async def test_admin_jobs_list_filters_by_status_and_tenant(tmp_path: Path) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    store = JobStore(jobs_dir=config.jobs_dir)
    app.dependency_overrides[deps.get_config] = async_override(config)
    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(
        ArtifactsService(store=store, jobs_dir=config.jobs_dir)
    )
    app.dependency_overrides[deps.get_job_service] = async_override(_FakeJobService(store=store))
    default_job_id, tenant_job_id = _seed_jobs(config=config, store=store)

    async with asgi_client(app=app) as client:
        auth_headers = await _admin_auth_headers(client=client)
        listed = await client.get("/api/admin/jobs", headers=auth_headers)
        assert listed.status_code == 200
        assert {job["job_id"] for job in listed.json()["jobs"]} == {default_job_id, tenant_job_id}

        failed = await client.get("/api/admin/jobs?status=failed", headers=auth_headers)
        assert failed.status_code == 200
        assert [job["job_id"] for job in failed.json()["jobs"]] == [default_job_id]

        tenant_only = await client.get("/api/admin/jobs?tenant_id=tenant-a", headers=auth_headers)
        assert tenant_only.status_code == 200
        assert [job["job_id"] for job in tenant_only.json()["jobs"]] == [tenant_job_id]


async def test_admin_job_detail_and_artifacts_download(tmp_path: Path) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    store = JobStore(jobs_dir=config.jobs_dir)
    app.dependency_overrides[deps.get_config] = async_override(config)
    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(
        ArtifactsService(store=store, jobs_dir=config.jobs_dir)
    )
    app.dependency_overrides[deps.get_job_service] = async_override(_FakeJobService(store=store))
    default_job_id, tenant_job_id = _seed_jobs(config=config, store=store)

    async with asgi_client(app=app) as client:
        auth_headers = await _admin_auth_headers(client=client)

        detail_default = await client.get(f"/api/admin/jobs/{default_job_id}", headers=auth_headers)
        assert detail_default.status_code == 200
        assert detail_default.json()["draft_text"] == "draft-default"

        detail_tenant = await client.get(
            f"/api/admin/jobs/{tenant_job_id}",
            headers={**auth_headers, "X-SS-Tenant-ID": "tenant-a"},
        )
        assert detail_tenant.status_code == 200
        assert detail_tenant.json()["tenant_id"] == "tenant-a"

        artifacts_list = await client.get(
            f"/api/admin/jobs/{default_job_id}/artifacts",
            headers=auth_headers,
        )
        assert artifacts_list.status_code == 200
        assert artifacts_list.json()[0]["rel_path"] == "outputs/stdout.txt"

        downloaded = await client.get(
            f"/api/admin/jobs/{default_job_id}/artifacts/outputs/stdout.txt",
            headers=auth_headers,
        )
        assert downloaded.status_code == 200
        assert downloaded.content == b"hello"


async def test_admin_job_retry_sets_scheduled_at(tmp_path: Path) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    store = JobStore(jobs_dir=config.jobs_dir)
    app.dependency_overrides[deps.get_config] = async_override(config)
    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(
        ArtifactsService(store=store, jobs_dir=config.jobs_dir)
    )
    app.dependency_overrides[deps.get_job_service] = async_override(_FakeJobService(store=store))
    default_job_id, _tenant_job_id = _seed_jobs(config=config, store=store)

    async with asgi_client(app=app) as client:
        auth_headers = await _admin_auth_headers(client=client)
        retried = await client.post(f"/api/admin/jobs/{default_job_id}/retry", headers=auth_headers)

    assert retried.status_code == 200
    assert retried.json()["status"] == "queued"
    assert retried.json()["scheduled_at"] is not None
