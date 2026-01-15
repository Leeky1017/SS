from __future__ import annotations

import httpx
import pytest

from tests.v1_redeem import redeem_job

pytestmark = pytest.mark.anyio


async def _upload_csv(*, client: httpx.AsyncClient, job_id: str) -> None:
    files = [("file", ("primary.csv", b"id,y,x\n1,2,3\n", "text/csv"))]
    response = await client.post(f"/v1/jobs/{job_id}/inputs/upload", files=files)
    assert response.status_code == 200


async def _prepare_draft_ready_job(*, client: httpx.AsyncClient, task_code: str) -> str:
    job_id, _token = await redeem_job(client=client, task_code=task_code, requirement="req")
    await _upload_csv(client=client, job_id=job_id)
    preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 200
    return job_id


async def test_confirm_when_missing_answers_and_unknowns_returns_400(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id = await _prepare_draft_ready_job(client=e2e_client, task_code="tc_e2e_confirm_blocked")

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

    assert response.status_code == 400
    payload = response.json()
    assert payload["error_code"] == "DRAFT_CONFIRM_BLOCKED"
    assert "missing_answers" in payload["message"]
    assert "unresolved_unknowns" in payload["message"]


async def test_confirm_is_idempotent_and_does_not_reschedule(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id = await _prepare_draft_ready_job(
        client=e2e_client, task_code="tc_e2e_confirm_idempotent"
    )
    patched = await e2e_client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    assert patched.status_code == 200

    first = await e2e_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )
    assert first.status_code == 200
    first_payload = first.json()
    assert first_payload["status"] == "queued"
    assert first_payload["scheduled_at"] is not None

    second = await e2e_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )
    assert second.status_code == 200
    second_payload = second.json()
    assert second_payload["status"] == "queued"
    assert second_payload["scheduled_at"] == first_payload["scheduled_at"]


async def test_after_confirm_inputs_upload_and_draft_patch_are_locked(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id = await _prepare_draft_ready_job(client=e2e_client, task_code="tc_e2e_confirm_lock")
    patched = await e2e_client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    assert patched.status_code == 200

    confirmed = await e2e_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )
    assert confirmed.status_code == 200
    assert confirmed.json()["status"] == "queued"

    upload = await e2e_client.post(
        f"/v1/jobs/{job_id}/inputs/upload",
        files=[("file", ("primary.csv", b"id,y\n1,2\n", "text/csv"))],
    )
    assert upload.status_code == 409
    assert upload.json()["error_code"] == "JOB_LOCKED"

    patch = await e2e_client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        json={"field_updates": {"outcome_var": "y2"}},
    )
    assert patch.status_code == 409
    assert patch.json()["error_code"] == "JOB_LOCKED"

