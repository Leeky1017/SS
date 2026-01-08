from __future__ import annotations

import httpx
import pytest

from src.domain.worker_service import WorkerService


async def _create_job(*, client: httpx.AsyncClient, requirement: str) -> str:
    response = await client.post("/v1/jobs", json={"requirement": requirement})
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "created"
    return str(payload["job_id"])


@pytest.mark.anyio
async def test_analysis_complete_flow_happy_path_transitions_and_downloads(
    journey_client: httpx.AsyncClient,
    journey_worker_service: WorkerService,
    journey_attach_sample_inputs,
) -> None:
    job_id = await _create_job(
        client=journey_client, requirement="estimate the effect of X on Y"
    )

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "created"
    assert payload["draft"] is None
    assert payload["artifacts"]["total"] == 0

    response = await journey_client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200
    preview = response.json()
    assert preview["job_id"] == job_id
    assert "estimate the effect of X on Y" in preview["draft_text"]

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "draft_ready"
    assert payload["draft"]["text_chars"] > 0

    journey_attach_sample_inputs(job_id)

    response = await journey_client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
    assert response.status_code == 200
    plan_payload = response.json()
    assert plan_payload["job_id"] == job_id
    assert plan_payload["plan"]["rel_path"] == "artifacts/plan.json"

    response = await journey_client.get(f"/v1/jobs/{job_id}/plan")
    assert response.status_code == 200
    assert response.json()["job_id"] == job_id

    response = await journey_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={"confirmed": True},
    )
    assert response.status_code == 200
    confirmed = response.json()
    assert confirmed["job_id"] == job_id
    assert confirmed["status"] == "queued"
    assert confirmed["scheduled_at"] is not None

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "queued"

    assert journey_worker_service.process_next(worker_id="worker_test") is True

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "succeeded"
    assert payload["latest_run"]["status"] == "succeeded"

    response = await journey_client.get(f"/v1/jobs/{job_id}/artifacts")
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
    response = await journey_client.get(f"/v1/jobs/{job_id}/artifacts/{rel_path}")
    assert response.status_code == 200
    assert b"metric" in response.content
