from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

import pytest

from src.infra.admin_exceptions import AdminTokenInvalidError, AdminTokenNotFoundError
from src.infra.file_admin_token_store import FileAdminTokenStore


def _read_token_payload(*, data_dir: Path, token_id: str) -> dict[str, object]:
    path = data_dir / "admin_tokens" / f"{token_id}.json"
    return json.loads(path.read_text(encoding="utf-8"))


def test_issue_token_persists_hashed_secret_and_returns_bearer_token(tmp_path: Path) -> None:
    store = FileAdminTokenStore(data_dir=tmp_path)
    now = datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc)

    issued = store.issue_token(name="personal", now=now)

    assert issued.token.startswith("ssa1.")
    payload = _read_token_payload(data_dir=tmp_path, token_id=issued.token_id)
    assert payload["token_id"] == issued.token_id
    assert payload["name"] == "personal"
    assert payload.get("secret_hash") not in {None, ""}
    assert "secret" not in payload


def test_authenticate_with_valid_token_updates_last_used_at(tmp_path: Path) -> None:
    store = FileAdminTokenStore(data_dir=tmp_path)
    now = datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
    later = datetime(2026, 1, 1, 0, 0, 1, tzinfo=timezone.utc)

    issued = store.issue_token(name="session:admin", now=now)

    meta = store.authenticate(token=issued.token, now=later)

    assert meta.token_id == issued.token_id
    payload = _read_token_payload(data_dir=tmp_path, token_id=issued.token_id)
    assert payload["last_used_at"] == later.isoformat()


def test_revoke_token_then_authenticate_raises_invalid(tmp_path: Path) -> None:
    store = FileAdminTokenStore(data_dir=tmp_path)
    now = datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc)

    issued = store.issue_token(name="personal", now=now)
    store.revoke_token(token_id=issued.token_id, now=now)

    with pytest.raises(AdminTokenInvalidError):
        store.authenticate(token=issued.token, now=now)


def test_delete_token_when_missing_raises_not_found(tmp_path: Path) -> None:
    store = FileAdminTokenStore(data_dir=tmp_path)

    with pytest.raises(AdminTokenNotFoundError):
        store.delete_token(token_id="token_missing")

