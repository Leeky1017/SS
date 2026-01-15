from __future__ import annotations

import httpx
import pytest

from tests.v1_redeem import redeem_job

pytestmark = pytest.mark.anyio


async def test_redeem_task_code_with_valid_payload_returns_job_and_token(
    e2e_client: httpx.AsyncClient,
) -> None:
    response = await e2e_client.post(
        "/v1/task-codes/redeem",
        json={"task_code": "tc_e2e_redeem_ok", "requirement": "req"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["job_id"].startswith("job_tc_")
    assert payload["token"].startswith("ssv1.")
    assert payload["expires_at"] != ""
    assert payload["is_idempotent"] is False


async def test_redeem_task_code_with_missing_fields_returns_400(
    e2e_client: httpx.AsyncClient,
) -> None:
    response = await e2e_client.post("/v1/task-codes/redeem", json={})

    assert response.status_code == 400
    assert response.json()["error_code"] == "INPUT_VALIDATION_FAILED"


@pytest.mark.parametrize(
    "method,path_template",
    [
        ("POST", "/v1/jobs/{job_id}/inputs/upload"),
        ("GET", "/v1/jobs/{job_id}/draft/preview"),
        ("POST", "/v1/jobs/{job_id}/confirm"),
        ("POST", "/v1/jobs/{job_id}/run"),
        ("GET", "/v1/jobs/{job_id}/artifacts/inputs/manifest.json"),
    ],
)
async def test_v1_endpoints_when_missing_token_return_401(
    e2e_client: httpx.AsyncClient,
    method: str,
    path_template: str,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_missing_token",
        requirement="req",
        set_auth_header=False,
    )
    path = path_template.format(job_id=job_id)
    if path.endswith("/confirm"):
        response = await e2e_client.request(
            method,
            path,
            json={
                "confirmed": True,
                "answers": {},
                "expert_suggestions_feedback": {},
                "variable_corrections": {},
                "default_overrides": {},
            },
        )
    elif path.endswith("/inputs/upload"):
        response = await e2e_client.request(method, path, files={})
    else:
        response = await e2e_client.request(method, path)

    assert response.status_code == 401
    assert response.json()["error_code"] == "AUTH_BEARER_TOKEN_MISSING"


async def test_inputs_upload_when_missing_file_returns_400(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_upload_missing_file",
        requirement="req",
    )
    response = await e2e_client.post(f"/v1/jobs/{job_id}/inputs/upload", files={})

    assert response.status_code == 400
    assert response.json()["error_code"] == "INPUT_VALIDATION_FAILED"


@pytest.mark.parametrize(
    "method,path_template",
    [
        ("POST", "/v1/jobs/{job_id}/inputs/upload"),
        ("GET", "/v1/jobs/{job_id}/draft/preview"),
        ("POST", "/v1/jobs/{job_id}/confirm"),
        ("POST", "/v1/jobs/{job_id}/run"),
        ("GET", "/v1/jobs/{job_id}/artifacts/inputs/manifest.json"),
    ],
)
async def test_v1_endpoints_when_invalid_auth_header_return_401(
    e2e_client: httpx.AsyncClient,
    method: str,
    path_template: str,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_invalid_auth_header",
        requirement="req",
        set_auth_header=False,
    )
    path = path_template.format(job_id=job_id)
    headers = {"Authorization": "Basic abc"}
    if path.endswith("/confirm"):
        response = await e2e_client.request(
            method,
            path,
            headers=headers,
            json={
                "confirmed": True,
                "answers": {},
                "expert_suggestions_feedback": {},
                "variable_corrections": {},
                "default_overrides": {},
            },
        )
    elif path.endswith("/inputs/upload"):
        response = await e2e_client.request(method, path, headers=headers, files={})
    else:
        response = await e2e_client.request(method, path, headers=headers)

    assert response.status_code == 401
    assert response.json()["error_code"] == "AUTH_BEARER_TOKEN_INVALID"


@pytest.mark.parametrize(
    "method,path_template",
    [
        ("POST", "/v1/jobs/{job_id}/inputs/upload"),
        ("GET", "/v1/jobs/{job_id}/draft/preview"),
        ("POST", "/v1/jobs/{job_id}/confirm"),
        ("POST", "/v1/jobs/{job_id}/run"),
        ("GET", "/v1/jobs/{job_id}/artifacts/inputs/manifest.json"),
    ],
)
async def test_v1_endpoints_when_token_invalid_return_403(
    e2e_client: httpx.AsyncClient,
    method: str,
    path_template: str,
) -> None:
    job_id, token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_invalid_token",
        requirement="req",
        set_auth_header=False,
    )
    bad_token = token.rsplit(".", 1)[0] + ".bad"
    path = path_template.format(job_id=job_id)
    headers = {"Authorization": f"Bearer {bad_token}"}
    if path.endswith("/confirm"):
        response = await e2e_client.request(
            method,
            path,
            headers=headers,
            json={
                "confirmed": True,
                "answers": {},
                "expert_suggestions_feedback": {},
                "variable_corrections": {},
                "default_overrides": {},
            },
        )
    elif path.endswith("/inputs/upload"):
        response = await e2e_client.request(method, path, headers=headers, files={})
    else:
        response = await e2e_client.request(method, path, headers=headers)

    assert response.status_code == 403
    assert response.json()["error_code"] == "AUTH_TOKEN_INVALID"


@pytest.mark.parametrize(
    "method,path_template",
    [
        ("POST", "/v1/jobs/{job_id}/inputs/upload"),
        ("GET", "/v1/jobs/{job_id}/draft/preview"),
        ("POST", "/v1/jobs/{job_id}/confirm"),
        ("POST", "/v1/jobs/{job_id}/run"),
        ("GET", "/v1/jobs/{job_id}/artifacts/inputs/manifest.json"),
    ],
)
async def test_v1_endpoints_when_job_missing_return_404(
    e2e_client: httpx.AsyncClient,
    method: str,
    path_template: str,
) -> None:
    job_id = "job_missing_404"
    path = path_template.format(job_id=job_id)
    if path.endswith("/confirm"):
        response = await e2e_client.request(
            method,
            path,
            json={
                "confirmed": True,
                "answers": {},
                "expert_suggestions_feedback": {},
                "variable_corrections": {},
                "default_overrides": {},
            },
        )
    elif path.endswith("/inputs/upload"):
        files = [("file", ("primary.csv", b"id,y\n1,2\n", "text/csv"))]
        response = await e2e_client.request(method, path, files=files)
    else:
        response = await e2e_client.request(method, path)

    assert response.status_code == 404
    assert response.json()["error_code"] == "JOB_NOT_FOUND"
