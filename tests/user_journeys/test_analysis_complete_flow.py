from __future__ import annotations

from fastapi.testclient import TestClient

from src.domain.models import JobConfirmation
from src.domain.plan_service import PlanService
from src.domain.worker_service import WorkerService


def _create_job(*, client: TestClient, requirement: str) -> str:
    response = client.post("/v1/jobs", json={"requirement": requirement})
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "created"
    return str(payload["job_id"])


def test_analysis_complete_flow_happy_path_transitions_and_downloads(
    journey_client: TestClient,
    journey_plan_service: PlanService,
    journey_worker_service: WorkerService,
    journey_attach_sample_inputs,
) -> None:
    job_id = _create_job(client=journey_client, requirement="estimate the effect of X on Y")

    response = journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "created"
    assert payload["draft"] is None
    assert payload["artifacts"]["total"] == 0

    response = journey_client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200
    preview = response.json()
    assert preview["job_id"] == job_id
    assert "estimate the effect of X on Y" in preview["draft_text"]

    response = journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "draft_ready"
    assert payload["draft"]["text_chars"] > 0

    journey_attach_sample_inputs(job_id)

    journey_plan_service.freeze_plan(
        job_id=job_id,
        confirmation=JobConfirmation(requirement="estimate the effect of X on Y"),
    )

    response = journey_client.post(f"/v1/jobs/{job_id}/confirm", json={"confirmed": True})
    assert response.status_code == 200
    confirmed = response.json()
    assert confirmed["job_id"] == job_id
    assert confirmed["status"] == "queued"
    assert confirmed["scheduled_at"] is not None

    response = journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "queued"

    assert journey_worker_service.process_next(worker_id="worker_test") is True

    response = journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "succeeded"
    assert payload["latest_run"]["status"] == "succeeded"

    response = journey_client.get(f"/v1/jobs/{job_id}/artifacts")
    assert response.status_code == 200
    artifacts_payload = response.json()
    assert artifacts_payload["job_id"] == job_id
    assert len(artifacts_payload["artifacts"]) > 0

    kinds = {item["kind"] for item in artifacts_payload["artifacts"]}
    assert {"stata.do", "stata.log", "run.meta.json", "stata.export.table"} <= kinds

    export = next(
        item
        for item in artifacts_payload["artifacts"]
        if item["kind"] == "stata.export.table"
    )
    rel_path = export["rel_path"]
    response = journey_client.get(f"/v1/jobs/{job_id}/artifacts/{rel_path}")
    assert response.status_code == 200
    assert b"metric" in response.content
