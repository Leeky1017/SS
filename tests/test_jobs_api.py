from __future__ import annotations

from datetime import datetime, timezone

import pytest

from src.api import deps
from src.domain.job_query_service import JobQueryService
from src.domain.models import ArtifactKind, ArtifactRef, Draft, RunAttempt
from src.domain.task_code_redeem_service import TaskCodeRedeemService
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


async def test_get_job_with_valid_job_returns_summary(job_service, store):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )

    job = job_service.create_job(requirement="hello")

    persisted = store.load(job.job_id)
    persisted.draft = Draft(text="draft text", created_at="2026-01-06T00:00:00+00:00")
    persisted.artifacts_index = [
        ArtifactRef(kind=ArtifactKind.LLM_PROMPT, rel_path="artifacts/llm/prompt.txt"),
        ArtifactRef(kind=ArtifactKind.LLM_PROMPT, rel_path="artifacts/llm/prompt2.txt"),
        ArtifactRef(kind=ArtifactKind.STATA_LOG, rel_path="artifacts/stata/stata.log"),
    ]
    persisted.runs = [
        RunAttempt(
            run_id="run_1",
            attempt=1,
            status="failed",
            started_at="2026-01-06T00:01:00+00:00",
            ended_at="2026-01-06T00:02:00+00:00",
            artifacts=[
                ArtifactRef(
                    kind=ArtifactKind.RUN_STDERR,
                    rel_path="runs/run_1/artifacts/stderr.txt",
                ),
            ],
        )
    ]
    store.save(persisted)

    async with asgi_client(app=app) as client:
        response = await client.get(f"/v1/jobs/{job.job_id}")

    assert response.status_code == 200
    payload = response.json()
    assert payload["job_id"] == job.job_id
    assert payload["status"] == "created"
    assert payload["timestamps"]["created_at"] == persisted.created_at
    assert payload["timestamps"]["scheduled_at"] is None

    assert payload["draft"]["created_at"] == "2026-01-06T00:00:00+00:00"
    assert payload["draft"]["text_chars"] == len("draft text")

    assert payload["artifacts"]["total"] == 3
    assert payload["artifacts"]["by_kind"]["llm.prompt"] == 2
    assert payload["artifacts"]["by_kind"]["stata.log"] == 1

    assert payload["latest_run"]["run_id"] == "run_1"
    assert payload["latest_run"]["artifacts_count"] == 1


async def test_get_job_with_missing_job_returns_404(job_service, store):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )

    async with asgi_client(app=app) as client:
        response = await client.get("/v1/jobs/job_missing")

    assert response.status_code == 404
    assert response.json()["error_code"] == "JOB_NOT_FOUND"


async def test_get_job_when_cross_tenant_access_returns_404(job_service, store) -> None:
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )
    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_task_code_redeem_service] = async_override(
        TaskCodeRedeemService(
            store=store,
            now=lambda: datetime(2099, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
        )
    )

    async with asgi_client(app=app) as client:
        redeemed = await client.post(
            "/v1/task-codes/redeem",
            json={"task_code": "tc_tenant_a", "requirement": "hello"},
            headers={"X-SS-Tenant-ID": "tenant-a"},
        )
        assert redeemed.status_code == 200
        job_id = redeemed.json()["job_id"]

    async with asgi_client(app=app) as client:
        response = await client.get(
            f"/v1/jobs/{job_id}",
            headers={"X-SS-Tenant-ID": "tenant-b"},
        )

    assert response.status_code == 404
    assert response.json()["error_code"] == "JOB_NOT_FOUND"


async def test_get_job_with_corrupted_job_json_returns_500(job_service, store, jobs_dir):
    job_id = "job_corrupt_json"
    job_dir = jobs_dir / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    (job_dir / "job.json").write_text("{", encoding="utf-8")

    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )

    async with asgi_client(app=app) as client:
        response = await client.get(f"/v1/jobs/{job_id}")

    assert response.status_code == 500
    assert response.json()["error_code"] == "JOB_DATA_CORRUPTED"


async def test_get_job_with_legacy_route_returns_404(job_service, store):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )

    job = job_service.create_job(requirement="hello")

    async with asgi_client(app=app) as client:
        response = await client.get(f"/jobs/{job.job_id}")

    assert response.status_code == 404


async def test_get_job_includes_request_id_header(job_service, store) -> None:
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )

    job = job_service.create_job(requirement="hello")

    async with asgi_client(app=app) as client:
        response = await client.get(f"/v1/jobs/{job.job_id}")

    assert response.status_code == 200
    assert response.headers.get("X-SS-Request-Id")


async def test_get_job_request_id_header_honors_incoming_x_request_id(job_service, store) -> None:
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )

    job = job_service.create_job(requirement="hello")

    async with asgi_client(app=app) as client:
        response = await client.get(f"/v1/jobs/{job.job_id}", headers={"X-Request-Id": "req-123"})

    assert response.status_code == 200
    assert response.headers["X-SS-Request-Id"] == "req-123"
