from __future__ import annotations

import httpx
import pytest

from tests.v1_redeem import redeem_job


async def _create_job(*, client: httpx.AsyncClient, requirement: str) -> str:
    job_id, _token = await redeem_job(
        client=client,
        task_code="tc_journey_draft_modification_loop",
        requirement=requirement,
    )
    return job_id


async def _preview(*, client: httpx.AsyncClient, job_id: str) -> str:
    response = await client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200
    return str(response.json()["draft_text"])


async def _artifact_count(*, client: httpx.AsyncClient, job_id: str) -> int:
    response = await client.get(f"/v1/jobs/{job_id}/artifacts")
    assert response.status_code == 200
    return len(response.json()["artifacts"])


@pytest.mark.anyio
async def test_draft_modification_loop_multiple_previews_accumulate_llm_artifacts(
    journey_client: httpx.AsyncClient,
    journey_attach_sample_inputs,
) -> None:
    job_id = await _create_job(client=journey_client, requirement="run a simple regression")
    journey_attach_sample_inputs(job_id)

    before = await _artifact_count(client=journey_client, job_id=job_id)
    first = await _preview(client=journey_client, job_id=job_id)
    after_first = await _artifact_count(client=journey_client, job_id=job_id)
    second = await _preview(client=journey_client, job_id=job_id)
    after_second = await _artifact_count(client=journey_client, job_id=job_id)

    assert before == 0
    assert first == second
    assert after_first > before
    assert after_second > after_first

    response = await journey_client.get(f"/v1/jobs/{job_id}")
    assert response.status_code == 200
    assert response.json()["status"] == "draft_ready"
