from __future__ import annotations

import json
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

from src.api import deps
from src.config import Config, load_config
from src.main import create_app
from src.utils.tenancy import TENANTS_DIRNAME
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override
from tests.fakes.fake_llm_client import FakeLLMClient

pytestmark = pytest.mark.anyio


def _test_config(*, tmp_path: Path) -> Config:
    env = dict(os.environ)
    env["SS_JOBS_DIR"] = str(tmp_path / "jobs")
    env["SS_QUEUE_DIR"] = str(tmp_path / "queue")
    env["SS_ADMIN_DATA_DIR"] = str(tmp_path / "admin")
    env["SS_ADMIN_USERNAME"] = "admin"
    env["SS_ADMIN_PASSWORD"] = "admin"
    return load_config(env)


async def _admin_login(*, client) -> str:
    login = await client.post(
        "/api/admin/auth/login",
        json={"username": "admin", "password": "admin"},
    )
    assert login.status_code == 200
    return str(login.json()["token"])


async def test_admin_tokens_when_missing_token_returns_401_with_stable_error_code(
    tmp_path: Path,
) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    app.dependency_overrides[deps.get_config] = async_override(config)

    async with asgi_client(app=app) as client:
        response = await client.get("/api/admin/tokens")

    assert response.status_code == 401
    assert response.json()["error_code"] == "ADMIN_BEARER_TOKEN_MISSING"


@pytest.mark.parametrize(
    ("authorization", "expected_error_code"),
    [
        ("", "ADMIN_BEARER_TOKEN_INVALID"),
        ("Token abc", "ADMIN_BEARER_TOKEN_INVALID"),
        ("Bearer ", "ADMIN_BEARER_TOKEN_INVALID"),
    ],
)
async def test_admin_tokens_when_invalid_authorization_returns_401(
    tmp_path: Path,
    authorization: str,
    expected_error_code: str,
) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    app.dependency_overrides[deps.get_config] = async_override(config)

    async with asgi_client(app=app) as client:
        response = await client.get("/api/admin/tokens", headers={"Authorization": authorization})

    assert response.status_code == 401
    assert response.json()["error_code"] == expected_error_code


async def test_admin_login_then_create_and_list_task_codes(tmp_path: Path) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    app.dependency_overrides[deps.get_config] = async_override(config)

    async with asgi_client(app=app) as client:
        token = await _admin_login(client=client)

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

async def test_admin_token_management_and_logout_invalidates_session(tmp_path: Path) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    app.dependency_overrides[deps.get_config] = async_override(config)

    async with asgi_client(app=app) as client:
        session_token = await _admin_login(client=client)
        auth_headers = {"Authorization": f"Bearer {session_token}"}

        created = await client.post(
            "/api/admin/tokens",
            json={"name": "test"},
            headers=auth_headers,
        )
        assert created.status_code == 200
        created_token_id = created.json()["token_id"]

        listed = await client.get("/api/admin/tokens", headers=auth_headers)
        assert listed.status_code == 200
        assert any(item["token_id"] == created_token_id for item in listed.json()["tokens"])

        revoked = await client.post(
            f"/api/admin/tokens/{created_token_id}/revoke",
            headers=auth_headers,
        )
        assert revoked.status_code == 200
        assert revoked.json()["revoked_at"] is not None

        deleted = await client.delete(f"/api/admin/tokens/{created_token_id}", headers=auth_headers)
        assert deleted.status_code == 204

        logout = await client.post("/api/admin/auth/logout", headers=auth_headers)
        assert logout.status_code == 200

        after_logout = await client.get("/api/admin/tokens", headers=auth_headers)
        assert after_logout.status_code == 403
        assert after_logout.json()["error_code"] == "ADMIN_TOKEN_INVALID"


async def test_admin_tenants_list_includes_only_safe_entries(tmp_path: Path) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    app.dependency_overrides[deps.get_config] = async_override(config)

    tenants_root = config.jobs_dir / TENANTS_DIRNAME
    (tenants_root / "tenant-a").mkdir(parents=True, exist_ok=True)
    (tenants_root / "~evil").mkdir(parents=True, exist_ok=True)

    async with asgi_client(app=app) as client:
        token = await _admin_login(client=client)
        auth_headers = {"Authorization": f"Bearer {token}"}

        response = await client.get("/api/admin/tenants", headers=auth_headers)

    assert response.status_code == 200
    assert response.json()["tenants"] == ["default", "tenant-a"]


async def test_admin_system_status_reports_queue_depth_and_workers(tmp_path: Path) -> None:
    app = create_app()
    config = _test_config(tmp_path=tmp_path)
    app.dependency_overrides[deps.get_config] = async_override(config)
    app.dependency_overrides[deps.get_llm_client] = async_override(FakeLLMClient())

    queued_dir = config.queue_dir / "queued"
    claimed_dir = config.queue_dir / "claimed"
    queued_dir.mkdir(parents=True, exist_ok=True)
    claimed_dir.mkdir(parents=True, exist_ok=True)
    (queued_dir / "job_queued.json").write_text(
        json.dumps({"job_id": "job_queued"}),
        encoding="utf-8",
    )
    now = datetime.now(timezone.utc)
    claim_payload = {
        "tenant_id": "default",
        "job_id": "job_claimed",
        "claim_id": "claim-1",
        "worker_id": "worker-test",
        "claimed_at": (now - timedelta(seconds=1)).isoformat(),
        "lease_expires_at": (now + timedelta(minutes=10)).isoformat(),
    }
    (claimed_dir / "job_claimed.json").write_text(
        json.dumps(claim_payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    async with asgi_client(app=app) as client:
        token = await _admin_login(client=client)
        system = await client.get(
            "/api/admin/system/status",
            headers={"Authorization": f"Bearer {token}"},
        )

    assert system.status_code == 200
    payload = system.json()
    assert payload["queue"]["queued"] >= 1
    assert payload["queue"]["claimed"] >= 1
    assert any(item["worker_id"] == "worker-test" for item in payload["workers"])
