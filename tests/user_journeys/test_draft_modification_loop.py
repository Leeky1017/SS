from __future__ import annotations

from fastapi.testclient import TestClient


def _create_job(*, client: TestClient, requirement: str) -> str:
    response = client.post("/v1/jobs", json={"requirement": requirement})
    assert response.status_code == 200
    return str(response.json()["job_id"])


def _preview(*, client: TestClient, job_id: str) -> str:
    response = client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200
    return str(response.json()["draft_text"])


def _artifact_count(*, client: TestClient, job_id: str) -> int:
    response = client.get(f"/v1/jobs/{job_id}/artifacts")
    assert response.status_code == 200
    return len(response.json()["artifacts"])


def test_draft_modification_loop_multiple_previews_accumulate_llm_artifacts(
    journey_client: TestClient,
) -> None:
    job_id = _create_job(client=journey_client, requirement="run a simple regression")

    before = _artifact_count(client=journey_client, job_id=job_id)
    first = _preview(client=journey_client, job_id=job_id)
    after_first = _artifact_count(client=journey_client, job_id=job_id)
    second = _preview(client=journey_client, job_id=job_id)
    after_second = _artifact_count(client=journey_client, job_id=job_id)

    assert before == 0
    assert first == second
    assert after_first > before
    assert after_second > after_first

    response = journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "draft_ready"

