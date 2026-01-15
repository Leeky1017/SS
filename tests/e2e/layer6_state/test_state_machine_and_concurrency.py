from __future__ import annotations

import anyio
import httpx
import pytest
from fastapi import FastAPI

from tests.asgi_client import asgi_client
from tests.v1_redeem import redeem_job

pytestmark = pytest.mark.anyio


async def _upload_csv(*, client: httpx.AsyncClient, job_id: str) -> None:
    files = [("file", ("primary.csv", b"id,y,x\n1,2,3\n", "text/csv"))]
    response = await client.post(f"/v1/jobs/{job_id}/inputs/upload", files=files)
    assert response.status_code == 200


async def test_draft_preview_before_inputs_returns_202_pending(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_pending_inputs",
        requirement="req",
    )

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 202
    assert preview.json()["message"] == "pending_inputs_upload"


async def test_task_code_redeem_twice_returns_same_job_and_token(
    e2e_client: httpx.AsyncClient,
) -> None:
    first = await e2e_client.post(
        "/v1/task-codes/redeem",
        json={"task_code": "tc_e2e_task_code_idempotent", "requirement": "req"},
    )
    assert first.status_code == 200
    first_payload = first.json()
    assert first_payload["is_idempotent"] is False

    second = await e2e_client.post(
        "/v1/task-codes/redeem",
        json={"task_code": "tc_e2e_task_code_idempotent", "requirement": "req"},
    )
    assert second.status_code == 200
    second_payload = second.json()
    assert second_payload["is_idempotent"] is True
    assert second_payload["job_id"] == first_payload["job_id"]
    assert second_payload["token"] == first_payload["token"]


async def test_run_before_draft_ready_returns_409(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_run_illegal",
        requirement="req",
    )
    response = await e2e_client.post(f"/v1/jobs/{job_id}/run")

    assert response.status_code == 409
    assert response.json()["error_code"] == "JOB_ILLEGAL_TRANSITION"


async def test_confirm_before_draft_ready_returns_409(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_confirm_illegal",
        requirement="req",
    )
    response = await e2e_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={
            "confirmed": True,
            "answers": {},
            "expert_suggestions_feedback": {},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )

    assert response.status_code == 409
    assert response.json()["error_code"] == "JOB_ILLEGAL_TRANSITION"


async def test_download_unknown_artifact_returns_404(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_artifact_missing",
        requirement="req",
    )
    await _upload_csv(client=e2e_client, job_id=job_id)

    response = await e2e_client.get(f"/v1/jobs/{job_id}/artifacts/nope.txt")
    assert response.status_code == 404
    assert response.json()["error_code"] == "ARTIFACT_NOT_FOUND"


async def test_concurrent_confirm_is_user_friendly_and_idempotent(
    e2e_app: FastAPI,
) -> None:
    async with asgi_client(app=e2e_app) as c1, asgi_client(app=e2e_app) as c2:
        job_id, token = await redeem_job(
            client=c1,
            task_code="tc_e2e_concurrent_confirm",
            requirement="req",
        )
        c2.headers["Authorization"] = f"Bearer {token}"

        await _upload_csv(client=c1, job_id=job_id)
        preview = await c1.get(f"/v1/jobs/{job_id}/draft/preview")
        assert preview.status_code == 200
        patched = await c1.post(
            f"/v1/jobs/{job_id}/draft/patch",
            json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
        )
        assert patched.status_code == 200

        payload = {
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        }
        responses: list[httpx.Response] = []

        async def _post_confirm(client: httpx.AsyncClient) -> None:
            responses.append(await client.post(f"/v1/jobs/{job_id}/confirm", json=payload))

        async with anyio.create_task_group() as tg:
            tg.start_soon(_post_confirm, c1)
            tg.start_soon(_post_confirm, c2)

        assert sorted([r.status_code for r in responses]) == [200, 200]
        assert {r.json()["status"] for r in responses} == {"queued"}
