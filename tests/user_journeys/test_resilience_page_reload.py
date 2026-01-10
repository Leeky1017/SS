from __future__ import annotations

import httpx
import pytest

from src.domain.worker_service import WorkerService
from tests.v1_redeem import redeem_job


async def _create_and_preview(*, client: httpx.AsyncClient) -> str:
    job_id, _token = await redeem_job(
        client=client,
        task_code="tc_journey_resilience_reload",
        requirement="difference-in-differences",
    )
    return job_id


@pytest.mark.anyio
async def test_resilience_page_reload_and_worker_shutdown_recovery_is_idempotent(
    journey_client: httpx.AsyncClient,
    journey_worker_service: WorkerService,
    journey_attach_sample_inputs,
    ) -> None:
    job_id = await _create_and_preview(client=journey_client)

    journey_attach_sample_inputs(job_id)

    response = await journey_client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200

    patched = await journey_client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    assert patched.status_code == 200
    assert patched.json()["remaining_unknowns_count"] == 0

    response = await journey_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )
    assert response.status_code == 200
    assert response.json()["status"] == "queued"

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "queued"

    response = await journey_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        },
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
