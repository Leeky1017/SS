from __future__ import annotations

import os
from urllib.parse import quote

import pytest

from src.api import deps
from src.domain.artifacts_service import ArtifactsService
from src.domain.models import ArtifactKind, ArtifactRef
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


async def test_get_job_artifacts_with_valid_job_returns_index(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(
        ArtifactsService(store=store, jobs_dir=jobs_dir)
    )

    job = job_service.create_job(requirement="hello")

    persisted = store.load(job.job_id)
    persisted.artifacts_index = [
        ArtifactRef(
            kind=ArtifactKind.LLM_PROMPT,
            rel_path="artifacts/llm/prompt.txt",
            created_at="2026-01-06T00:00:00+00:00",
            meta={"size_bytes": 123},
        )
    ]
    store.save(persisted)

    async with asgi_client(app=app) as client:
        response = await client.get(f"/v1/jobs/{job.job_id}/artifacts")

    assert response.status_code == 200
    payload = response.json()
    assert payload["job_id"] == job.job_id
    assert payload["artifacts"] == [
        {
            "kind": "llm.prompt",
            "rel_path": "artifacts/llm/prompt.txt",
            "created_at": "2026-01-06T00:00:00+00:00",
            "meta": {"size_bytes": 123},
        }
    ]


async def test_download_job_artifact_with_missing_artifact_returns_404(
    job_service, store, jobs_dir
):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(
        ArtifactsService(store=store, jobs_dir=jobs_dir)
    )

    job = job_service.create_job(requirement="hello")

    async with asgi_client(app=app) as client:
        response = await client.get(
            f"/v1/jobs/{job.job_id}/artifacts/artifacts/llm/missing.txt"
        )

    assert response.status_code == 404
    assert response.json()["error_code"] == "ARTIFACT_NOT_FOUND"


async def test_download_job_artifact_with_unsafe_path_returns_400(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(
        ArtifactsService(store=store, jobs_dir=jobs_dir)
    )

    job = job_service.create_job(requirement="hello")

    unsafe = quote("../job.json", safe="")
    async with asgi_client(app=app) as client:
        response = await client.get(f"/v1/jobs/{job.job_id}/artifacts/{unsafe}")

    assert response.status_code == 400
    assert response.json()["error_code"] == "ARTIFACT_PATH_UNSAFE"


async def test_download_job_artifact_with_symlink_escape_returns_400(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(
        ArtifactsService(store=store, jobs_dir=jobs_dir)
    )

    job = job_service.create_job(requirement="hello")
    outside = jobs_dir / "outside.txt"
    outside.write_text("secret", encoding="utf-8")

    persisted = store.load(job.job_id)
    persisted.artifacts_index = [
        ArtifactRef(kind=ArtifactKind.RUN_STDERR, rel_path="artifacts/evil.txt")
    ]
    store.save(persisted)

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    evil_path = job_dir / "artifacts" / "evil.txt"
    evil_path.parent.mkdir(parents=True, exist_ok=True)
    os.symlink(outside, evil_path)

    async with asgi_client(app=app) as client:
        response = await client.get(f"/v1/jobs/{job.job_id}/artifacts/artifacts/evil.txt")

    assert response.status_code == 400
    assert response.json()["error_code"] == "ARTIFACT_PATH_UNSAFE"


async def test_run_job_when_called_twice_is_idempotent(job_service, store, draft_service):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)

    job = job_service.create_job(requirement=None)
    await draft_service.preview(job_id=job.job_id)

    async with asgi_client(app=app) as client:
        first = await client.post(f"/v1/jobs/{job.job_id}/run")
        second = await client.post(f"/v1/jobs/{job.job_id}/run")

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["status"] == "queued"
    assert second.json()["status"] == "queued"
    assert second.json()["scheduled_at"] == first.json()["scheduled_at"]
