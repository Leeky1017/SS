from __future__ import annotations

import httpx
from fastapi.testclient import TestClient


async def redeem_job(
    *,
    client: httpx.AsyncClient,
    task_code: str,
    requirement: str,
    set_auth_header: bool = True,
) -> tuple[str, str]:
    response = await client.post(
        "/v1/task-codes/redeem",
        json={"task_code": task_code, "requirement": requirement},
    )
    assert response.status_code == 200
    payload = response.json()
    token = str(payload["token"])
    if set_auth_header:
        client.headers["Authorization"] = f"Bearer {token}"
    return str(payload["job_id"]), token


def redeem_job_sync(
    *,
    client: TestClient,
    task_code: str,
    requirement: str,
    set_auth_header: bool = True,
) -> tuple[str, str]:
    response = client.post(
        "/v1/task-codes/redeem",
        json={"task_code": task_code, "requirement": requirement},
    )
    assert response.status_code == 200
    payload = response.json()
    token = str(payload["token"])
    if set_auth_header:
        client.headers.update({"Authorization": f"Bearer {token}"})
    return str(payload["job_id"]), token

