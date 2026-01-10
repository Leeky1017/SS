from __future__ import annotations

from datetime import datetime, timezone

import pytest

from src.api import deps
from src.domain.job_query_service import JobQueryService
from src.domain.task_code_redeem_service import TaskCodeRedeemService
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _dt(value: str) -> datetime:
    return datetime.fromisoformat(value).astimezone(timezone.utc)


async def test_redeem_with_same_task_code_returns_stable_job_and_token_and_refreshes_expires_at(
    store,
) -> None:
    now_values = [
        datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
        datetime(2026, 1, 2, 0, 0, 0, tzinfo=timezone.utc),
    ]

    def now() -> datetime:
        return now_values.pop(0)

    redeem_service = TaskCodeRedeemService(store=store, now=now)
    app = create_app()
    app.dependency_overrides[deps.get_task_code_redeem_service] = async_override(redeem_service)
    app.dependency_overrides[deps.get_job_store] = async_override(store)

    async with asgi_client(app=app) as client:
        first = await client.post(
            "/v1/task-codes/redeem",
            json={"task_code": "tc_demo_01", "requirement": "req_v1"},
        )
        second = await client.post(
            "/v1/task-codes/redeem",
            json={"task_code": "tc_demo_01", "requirement": "req_v2"},
        )

    assert first.status_code == 200
    assert second.status_code == 200

    first_payload = first.json()
    second_payload = second.json()

    assert first_payload["job_id"] == second_payload["job_id"]
    assert first_payload["token"] == second_payload["token"]
    assert first_payload["is_idempotent"] is False
    assert second_payload["is_idempotent"] is True

    assert _dt(second_payload["expires_at"]) > _dt(first_payload["expires_at"])

    persisted = store.load(first_payload["job_id"])
    assert persisted.requirement == "req_v1"


async def test_job_route_when_missing_token_returns_401_with_stable_error_code(store) -> None:
    redeem_service = TaskCodeRedeemService(
        store=store,
        now=lambda: datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
    )
    app = create_app()
    app.dependency_overrides[deps.get_task_code_redeem_service] = async_override(redeem_service)
    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )

    async with asgi_client(app=app) as client:
        redeemed = await client.post(
            "/v1/task-codes/redeem",
            json={"task_code": "tc_demo_01", "requirement": ""},
        )
        job_id = redeemed.json()["job_id"]
        response = await client.get(f"/v1/jobs/{job_id}")

    assert response.status_code == 401
    assert response.json()["error_code"] == "AUTH_BEARER_TOKEN_MISSING"


async def test_job_route_when_wrong_token_returns_403_with_stable_error_code(store) -> None:
    redeem_service = TaskCodeRedeemService(
        store=store,
        now=lambda: datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
    )
    app = create_app()
    app.dependency_overrides[deps.get_task_code_redeem_service] = async_override(redeem_service)
    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )

    async with asgi_client(app=app) as client:
        redeemed_a = await client.post(
            "/v1/task-codes/redeem",
            json={"task_code": "tc_demo_01", "requirement": ""},
        )
        redeemed_b = await client.post(
            "/v1/task-codes/redeem",
            json={"task_code": "tc_demo_02", "requirement": ""},
        )
        job_a = redeemed_a.json()["job_id"]
        token_b = redeemed_b.json()["token"]

        invalid = await client.get(
            f"/v1/jobs/{job_a}",
            headers={"Authorization": "Bearer wrong_token"},
        )
        forbidden = await client.get(
            f"/v1/jobs/{job_a}",
            headers={"Authorization": f"Bearer {token_b}"},
        )

    assert invalid.status_code == 403
    assert invalid.json()["error_code"] == "AUTH_TOKEN_INVALID"

    assert forbidden.status_code == 403
    assert forbidden.json()["error_code"] == "AUTH_TOKEN_FORBIDDEN"


async def test_post_v1_jobs_returns_404(store) -> None:
    app = create_app()
    app.dependency_overrides[deps.get_job_store] = async_override(store)

    async with asgi_client(app=app) as client:
        response = await client.post("/v1/jobs", json={"requirement": "hello"})

    assert response.status_code == 404
