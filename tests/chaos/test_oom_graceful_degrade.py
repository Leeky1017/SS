from __future__ import annotations

import logging

import pytest

from src.api import deps
from src.main import create_app
from src.utils.tenancy import DEFAULT_TENANT_ID
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override


@pytest.mark.anyio
async def test_create_job_when_oom_returns_user_friendly_error(caplog) -> None:
    class OOMRedeemService:
        def redeem(self, *, tenant_id: str = DEFAULT_TENANT_ID, task_code: str, requirement: str):  # noqa: ANN001
            raise MemoryError("simulated oom")

    app = create_app()
    app.dependency_overrides[deps.get_task_code_redeem_service] = async_override(OOMRedeemService())

    with caplog.at_level(logging.ERROR):
        async with asgi_client(app=app) as client:
            response = await client.post(
                "/v1/task-codes/redeem",
                json={"task_code": "tc_oom", "requirement": "hello"},
            )

    assert response.status_code == 503
    payload = response.json()
    assert payload["error_code"] == "RESOURCE_OOM"
    assert "Traceback" not in payload["message"]

    records = [r for r in caplog.records if r.msg == "SS_RESOURCE_OOM"]
    assert len(records) == 1
