from __future__ import annotations

from fastapi.testclient import TestClient

from src.api import deps
from src.domain.artifacts_service import ArtifactsService
from src.domain.job_query_service import JobQueryService
from src.domain.plan_service import PlanService
from src.main import create_app


def _test_client(*, job_service, draft_service, store, jobs_dir) -> TestClient:  # noqa: ANN001
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = lambda: job_service
    app.dependency_overrides[deps.get_job_query_service] = lambda: JobQueryService(store=store)
    app.dependency_overrides[deps.get_draft_service] = lambda: draft_service
    app.dependency_overrides[deps.get_artifacts_service] = lambda: ArtifactsService(
        store=store, jobs_dir=jobs_dir
    )
    app.dependency_overrides[deps.get_plan_service] = lambda: PlanService(store=store)
    return TestClient(app)


def test_freeze_plan_when_job_not_ready_returns_409(
    job_service, draft_service, store, jobs_dir
) -> None:
    client = _test_client(
        job_service=job_service, draft_service=draft_service, store=store, jobs_dir=jobs_dir
    )
    created = client.post("/v1/jobs", json={"requirement": "hello"})
    assert created.status_code == 200
    job_id = created.json()["job_id"]

    response = client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})

    assert response.status_code == 409
    assert response.json()["error_code"] == "PLAN_FREEZE_NOT_ALLOWED"


def test_freeze_plan_then_get_plan_returns_plan(
    job_service, draft_service, store, jobs_dir
) -> None:
    client = _test_client(
        job_service=job_service, draft_service=draft_service, store=store, jobs_dir=jobs_dir
    )
    created = client.post("/v1/jobs", json={"requirement": "hello"})
    assert created.status_code == 200
    job_id = created.json()["job_id"]

    preview = client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 200

    frozen = client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
    assert frozen.status_code == 200
    assert frozen.json()["plan"]["rel_path"] == "artifacts/plan.json"

    got = client.get(f"/v1/jobs/{job_id}/plan")
    assert got.status_code == 200
    assert got.json()["plan"]["plan_id"] == frozen.json()["plan"]["plan_id"]


def test_confirm_auto_freezes_plan_before_queueing(
    job_service, draft_service, store, jobs_dir
) -> None:
    client = _test_client(
        job_service=job_service, draft_service=draft_service, store=store, jobs_dir=jobs_dir
    )
    created = client.post("/v1/jobs", json={"requirement": "hello"})
    assert created.status_code == 200
    job_id = created.json()["job_id"]

    preview = client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 200

    confirmed = client.post(f"/v1/jobs/{job_id}/confirm", json={"confirmed": True})
    assert confirmed.status_code == 200
    assert confirmed.json()["status"] == "queued"

    got = client.get(f"/v1/jobs/{job_id}/plan")
    assert got.status_code == 200
    assert got.json()["plan"]["rel_path"] == "artifacts/plan.json"


def test_freeze_plan_when_called_twice_is_idempotent(
    job_service, draft_service, store, jobs_dir
) -> None:
    client = _test_client(
        job_service=job_service, draft_service=draft_service, store=store, jobs_dir=jobs_dir
    )
    created = client.post("/v1/jobs", json={"requirement": "hello"})
    assert created.status_code == 200
    job_id = created.json()["job_id"]

    preview = client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 200

    first = client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
    second = client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
    assert first.status_code == 200
    assert second.status_code == 200
    assert second.json()["plan"]["plan_id"] == first.json()["plan"]["plan_id"]

    artifacts = client.get(f"/v1/jobs/{job_id}/artifacts")
    assert artifacts.status_code == 200
    plan_entries = [a for a in artifacts.json()["artifacts"] if a["kind"] == "plan.json"]
    assert len(plan_entries) == 1
    assert plan_entries[0]["rel_path"] == "artifacts/plan.json"


def test_freeze_plan_when_notes_change_returns_conflict(
    job_service, draft_service, store, jobs_dir
) -> None:
    client = _test_client(
        job_service=job_service, draft_service=draft_service, store=store, jobs_dir=jobs_dir
    )
    created = client.post("/v1/jobs", json={"requirement": "hello"})
    assert created.status_code == 200
    job_id = created.json()["job_id"]

    preview = client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 200

    first = client.post(f"/v1/jobs/{job_id}/plan/freeze", json={"notes": "v1"})
    assert first.status_code == 200

    conflict = client.post(f"/v1/jobs/{job_id}/plan/freeze", json={"notes": "v2"})
    assert conflict.status_code == 409
    assert conflict.json()["error_code"] == "PLAN_ALREADY_FROZEN_CONFLICT"
