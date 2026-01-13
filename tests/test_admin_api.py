from __future__ import annotations

import os
from pathlib import Path

import pytest

from src.api import deps
from src.config import load_config
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override
from tests.fakes.fake_llm_client import FakeLLMClient

pytestmark = pytest.mark.anyio


def _test_config(*, tmp_path: Path) -> object:
    env = dict(os.environ)
    env["SS_JOBS_DIR"] = str(tmp_path / "jobs")
    env["SS_QUEUE_DIR"] = str(tmp_path / "queue")
    env["SS_ADMIN_DATA_DIR"] = str(tmp_path / "admin")
    env["SS_ADMIN_USERNAME"] = "admin"
    env["SS_ADMIN_PASSWORD"] = "admin"
    return load_config(env)


async def test_admin_tokens_when_missing_token_returns_401_with_stable_error_code(
    tmp_path: Path,
) -> None:
    app = create_app()
    app.dependency_overrides[deps.get_config] = async_override(_test_config(tmp_path=tmp_path))

    async with asgi_client(app=app) as client:
        response = await client.get("/api/admin/tokens")

    assert response.status_code == 401
    assert response.json()["error_code"] == "ADMIN_BEARER_TOKEN_MISSING"


async def test_admin_login_then_create_and_list_task_codes(tmp_path: Path) -> None:
    app = create_app()
    app.dependency_overrides[deps.get_config] = async_override(_test_config(tmp_path=tmp_path))
    app.dependency_overrides[deps.get_llm_client] = async_override(FakeLLMClient())

    async with asgi_client(app=app) as client:
        login = await client.post(
            "/api/admin/auth/login",
            json={"username": "admin", "password": "admin"},
        )
        assert login.status_code == 200
        token = login.json()["token"]

        codes = await client.post(
            "/api/admin/task-codes",
            json={"count": 2, "expires_in_days": 30, "tenant_id": "default"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert codes.status_code == 200
        payload = codes.json()
        assert len(payload["task_codes"]) == 2
        assert all(item["status"] == "unused" for item in payload["task_codes"])

        listed = await client.get(
            "/api/admin/task-codes?status=unused",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert listed.status_code == 200
        assert len(listed.json()["task_codes"]) >= 2

        system = await client.get(
            "/api/admin/system/status",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert system.status_code == 200
        assert "health" in system.json()

