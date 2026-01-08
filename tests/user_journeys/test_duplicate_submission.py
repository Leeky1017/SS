from __future__ import annotations

from pathlib import Path

import httpx
import pytest

from src.domain.worker_service import WorkerService


async def _create_job_ready_for_submit(*, client: httpx.AsyncClient) -> str:
    response = await client.post(
        "/v1/jobs",
        json={"requirement": "run a regression and export table"},
    )
    assert response.status_code == 200
    job_id = str(response.json()["job_id"])

    response = await client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200
    return job_id


@pytest.mark.anyio
async def test_duplicate_submission_confirm_is_idempotent_and_queues_once(
    journey_client: httpx.AsyncClient,
    journey_worker_service: WorkerService,
    journey_queue_dir: Path,
    journey_attach_sample_inputs,
) -> None:
    job_id = await _create_job_ready_for_submit(client=journey_client)

    journey_attach_sample_inputs(job_id)

    response = await journey_client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
    assert response.status_code == 200

    responses = []
    url = f"/v1/jobs/{job_id}/confirm"
    for _ in range(3):
        responses.append(await journey_client.post(url, json={"confirmed": True}))
    assert all(resp.status_code == 200 for resp in responses)
    payloads = [resp.json() for resp in responses]
    assert {payload["status"] for payload in payloads} == {"queued"}
    assert len({payload["scheduled_at"] for payload in payloads}) == 1

    queued_dir = journey_queue_dir / "queued"
    queued_files = list(queued_dir.glob("*.json"))
    assert [p.stem for p in queued_files] == [job_id]

    assert journey_worker_service.process_next(worker_id="worker_test") is True

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "succeeded"
