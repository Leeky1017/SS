from __future__ import annotations

import asyncio
import os
from urllib.parse import quote

from fastapi.testclient import TestClient

from src.api import deps
from src.domain.artifacts_service import ArtifactsService
from src.domain.models import ArtifactKind, ArtifactRef
from src.main import create_app


def test_get_job_artifacts_with_valid_job_returns_index(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = lambda: job_service
    app.dependency_overrides[deps.get_artifacts_service] = lambda: ArtifactsService(
        store=store, jobs_dir=jobs_dir
    )
    client = TestClient(app)

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

    response = client.get(f"/v1/jobs/{job.job_id}/artifacts")

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


def test_download_job_artifact_with_missing_artifact_returns_404(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = lambda: job_service
    app.dependency_overrides[deps.get_artifacts_service] = lambda: ArtifactsService(
        store=store, jobs_dir=jobs_dir
    )
    client = TestClient(app)

    job = job_service.create_job(requirement="hello")

    response = client.get(f"/v1/jobs/{job.job_id}/artifacts/artifacts/llm/missing.txt")

    assert response.status_code == 404
    assert response.json()["error_code"] == "ARTIFACT_NOT_FOUND"


def test_download_job_artifact_with_unsafe_path_returns_400(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = lambda: job_service
    app.dependency_overrides[deps.get_artifacts_service] = lambda: ArtifactsService(
        store=store, jobs_dir=jobs_dir
    )
    client = TestClient(app)

    job = job_service.create_job(requirement="hello")

    unsafe = quote("../job.json", safe="")
    response = client.get(f"/v1/jobs/{job.job_id}/artifacts/{unsafe}")

    assert response.status_code == 400
    assert response.json()["error_code"] == "ARTIFACT_PATH_UNSAFE"


def test_download_job_artifact_with_symlink_escape_returns_400(job_service, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = lambda: job_service
    app.dependency_overrides[deps.get_artifacts_service] = lambda: ArtifactsService(
        store=store, jobs_dir=jobs_dir
    )
    client = TestClient(app)

    job = job_service.create_job(requirement="hello")
    outside = jobs_dir / "outside.txt"
    outside.write_text("secret", encoding="utf-8")

    persisted = store.load(job.job_id)
    persisted.artifacts_index = [
        ArtifactRef(kind=ArtifactKind.RUN_STDERR, rel_path="artifacts/evil.txt")
    ]
    store.save(persisted)

    evil_path = jobs_dir / job.job_id / "artifacts" / "evil.txt"
    evil_path.parent.mkdir(parents=True, exist_ok=True)
    os.symlink(outside, evil_path)

    response = client.get(f"/v1/jobs/{job.job_id}/artifacts/artifacts/evil.txt")

    assert response.status_code == 400
    assert response.json()["error_code"] == "ARTIFACT_PATH_UNSAFE"


def test_run_job_when_called_twice_is_idempotent(job_service, store, draft_service):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = lambda: job_service
    client = TestClient(app)

    job = job_service.create_job(requirement=None)
    asyncio.run(draft_service.preview(job_id=job.job_id))

    first = client.post(f"/v1/jobs/{job.job_id}/run")
    second = client.post(f"/v1/jobs/{job.job_id}/run")

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["status"] == "queued"
    assert second.json()["status"] == "queued"
    assert second.json()["scheduled_at"] == first.json()["scheduled_at"]
