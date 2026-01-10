from __future__ import annotations

from pathlib import Path

import httpx
import pytest

from src.domain.worker_service import WorkerService
from tests.v1_redeem import redeem_job


async def _create_job_ready_for_submit(*, client: httpx.AsyncClient) -> str:
    job_id, _token = await redeem_job(
        client=client,
        task_code="tc_journey_duplicate_submission",
        requirement="run a regression and export table",
    )
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

    response = await journey_client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200

    patched = await journey_client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    assert patched.status_code == 200
    assert patched.json()["remaining_unknowns_count"] == 0

    responses = []
    url = f"/v1/jobs/{job_id}/confirm"
    for _ in range(3):
        responses.append(
            await journey_client.post(
                url,
                json={
                    "confirmed": True,
                    "answers": {"analysis_goal": "descriptive"},
                    "expert_suggestions_feedback": {"analysis_goal": "ok"},
                    "variable_corrections": {},
                    "default_overrides": {},
                },
            )
        )
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
