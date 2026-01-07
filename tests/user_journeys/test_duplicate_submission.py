from __future__ import annotations

from pathlib import Path

from fastapi.testclient import TestClient

from src.domain.models import JobConfirmation
from src.domain.plan_service import PlanService
from src.domain.worker_service import WorkerService


def _create_job_ready_for_submit(*, client: TestClient) -> str:
    response = client.post("/v1/jobs", json={"requirement": "run a regression and export table"})
    assert response.status_code == 200
    job_id = str(response.json()["job_id"])

    response = client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200
    return job_id


def test_duplicate_submission_confirm_is_idempotent_and_queues_once(
    journey_client: TestClient,
    journey_plan_service: PlanService,
    journey_worker_service: WorkerService,
    journey_queue_dir: Path,
    journey_attach_sample_inputs,
) -> None:
    job_id = _create_job_ready_for_submit(client=journey_client)

    journey_attach_sample_inputs(job_id)

    journey_plan_service.freeze_plan(
        job_id=job_id,
        confirmation=JobConfirmation(requirement="run a regression and export table"),
    )

    responses = []
    url = f"/v1/jobs/{job_id}/confirm"
    for _ in range(3):
        responses.append(journey_client.post(url, json={"confirmed": True}))
    assert all(resp.status_code == 200 for resp in responses)
    payloads = [resp.json() for resp in responses]
    assert {payload["status"] for payload in payloads} == {"queued"}
    assert len({payload["scheduled_at"] for payload in payloads}) == 1

    queued_dir = journey_queue_dir / "queued"
    queued_files = list(queued_dir.glob("*.json"))
    assert [p.stem for p in queued_files] == [job_id]

    assert journey_worker_service.process_next(worker_id="worker_test") is True

    response = journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "succeeded"
