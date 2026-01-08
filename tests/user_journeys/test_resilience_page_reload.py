from __future__ import annotations

import httpx
import pytest

from src.domain.worker_service import WorkerService


async def _create_and_preview(*, client: httpx.AsyncClient) -> str:
    response = await client.post("/v1/jobs", json={"requirement": "difference-in-differences"})
    assert response.status_code == 200
    job_id = str(response.json()["job_id"])
    response = await client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200
    return job_id


@pytest.mark.anyio
async def test_resilience_page_reload_and_worker_shutdown_recovery_is_idempotent(
    journey_client: httpx.AsyncClient,
    journey_worker_service: WorkerService,
    journey_attach_sample_inputs,
) -> None:
    job_id = await _create_and_preview(client=journey_client)

    journey_attach_sample_inputs(job_id)

    response = await journey_client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
    assert response.status_code == 200

    response = await journey_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={"confirmed": True},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "queued"

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "queued"

    response = await journey_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={"confirmed": True},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "queued"

    calls = 0

    def stop_requested() -> bool:
        nonlocal calls
        calls += 1
        return calls >= 2

    processed = journey_worker_service.process_next(
        worker_id="worker_test",
        stop_requested=stop_requested,
    )
    assert processed is False
    assert journey_worker_service.process_next(worker_id="worker_test") is True

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "succeeded"
