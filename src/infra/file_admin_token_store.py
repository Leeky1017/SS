from __future__ import annotations

import hashlib
import json
import logging
import secrets
import uuid
from datetime import datetime
from pathlib import Path
from typing import cast

from src.domain.admin_token_store import AdminTokenIssued, AdminTokenMetadata, AdminTokenStore
from src.infra.admin_exceptions import (
    AdminStoreIOError,
    AdminTokenInvalidError,
    AdminTokenNotFoundError,
)
from src.infra.atomic_write import atomic_write_json
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)

_TOKEN_PREFIX = "ssa1"


class FileAdminTokenStore(AdminTokenStore):
    def __init__(self, *, data_dir: Path):
        self._tokens_dir = Path(data_dir) / "admin_tokens"

    def issue_token(self, *, name: str, now: datetime) -> AdminTokenIssued:
        token_id = uuid.uuid4().hex
        secret = secrets.token_hex(16)
        token = f"{_TOKEN_PREFIX}.{token_id}.{secret}"
        record: JsonObject = {
            "token_id": token_id,
            "name": name,
            "created_at": now.isoformat(),
            "last_used_at": None,
            "revoked_at": None,
            "secret_hash": _sha256_hex(secret),
        }
        path = self._token_path(token_id=token_id)
        try:
            atomic_write_json(path=path, payload=record)
        except OSError as e:
            logger.warning(
                "SS_ADMIN_TOKEN_CREATE_FAILED",
                extra={"path": str(path), "error": str(e)},
            )
            raise AdminStoreIOError(operation="create_token", path=str(path)) from e
        return AdminTokenIssued(
            token_id=token_id,
            token=token,
            created_at=str(record["created_at"]),
        )

    def list_tokens(self) -> list[AdminTokenMetadata]:
        items: list[AdminTokenMetadata] = []
        for path in self._iter_token_files():
            meta = _load_token_meta(path=path)
            if meta is not None:
                items.append(meta)
        items.sort(key=lambda item: item.created_at, reverse=True)
        return items

    def revoke_token(self, *, token_id: str, now: datetime) -> AdminTokenMetadata:
        path = self._token_path(token_id=token_id)
        payload = _load_token_payload(path=path, token_id=token_id)
        if payload is None:
            raise AdminTokenNotFoundError(token_id=token_id)
        revoked_at = payload.get("revoked_at")
        if not isinstance(revoked_at, str) or revoked_at.strip() == "":
            payload["revoked_at"] = now.isoformat()
        try:
            atomic_write_json(path=path, payload=payload)
        except OSError as e:
            logger.warning(
                "SS_ADMIN_TOKEN_REVOKE_FAILED",
                extra={"path": str(path), "token_id": token_id, "error": str(e)},
            )
            raise AdminStoreIOError(operation="revoke_token", path=str(path)) from e
        meta = _meta_from_payload(payload)
        if meta is None:
            raise AdminTokenInvalidError()
        return meta

    def delete_token(self, *, token_id: str) -> None:
        path = self._token_path(token_id=token_id)
        if not path.exists():
            raise AdminTokenNotFoundError(token_id=token_id)
        try:
            path.unlink()
        except OSError as e:
            logger.warning(
                "SS_ADMIN_TOKEN_DELETE_FAILED",
                extra={"path": str(path), "token_id": token_id, "error": str(e)},
            )
            raise AdminStoreIOError(operation="delete_token", path=str(path)) from e

    def authenticate(self, *, token: str, now: datetime) -> AdminTokenMetadata:
        token_id, secret = _parse_token_or_raise(token)
        path = self._token_path(token_id=token_id)
        payload = _load_token_payload(path=path, token_id=token_id)
        if payload is None:
            raise AdminTokenInvalidError()
        revoked_at = payload.get("revoked_at")
        if isinstance(revoked_at, str) and revoked_at.strip() != "":
            raise AdminTokenInvalidError()
        expected_hash = payload.get("secret_hash")
        if not isinstance(expected_hash, str) or not secrets.compare_digest(
            expected_hash,
            _sha256_hex(secret),
        ):
            raise AdminTokenInvalidError()
        payload["last_used_at"] = now.isoformat()
        try:
            atomic_write_json(path=path, payload=payload)
        except OSError as e:
            logger.warning(
                "SS_ADMIN_TOKEN_TOUCH_FAILED",
                extra={"path": str(path), "token_id": token_id, "error": str(e)},
            )
            raise AdminStoreIOError(operation="touch_token", path=str(path)) from e
        meta = _meta_from_payload(payload)
        if meta is None:
            raise AdminTokenInvalidError()
        return meta

    def _token_path(self, *, token_id: str) -> Path:
        return self._tokens_dir / f"{token_id}.json"

    def _iter_token_files(self) -> list[Path]:
        if not self._tokens_dir.is_dir():
            return []
        try:
            return [p for p in self._tokens_dir.iterdir() if p.is_file() and p.suffix == ".json"]
        except OSError as e:
            logger.warning(
                "SS_ADMIN_TOKEN_LIST_FAILED",
                extra={"dir": str(self._tokens_dir), "error": str(e)},
            )
            return []


def _sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _parse_token_or_raise(token: str) -> tuple[str, str]:
    parts = token.strip().split(".")
    if len(parts) != 3 or parts[0] != _TOKEN_PREFIX:
        raise AdminTokenInvalidError()
    token_id = parts[1].strip()
    secret = parts[2].strip()
    if token_id == "" or secret == "":
        raise AdminTokenInvalidError()
    return token_id, secret


def _load_token_payload(*, path: Path, token_id: str) -> JsonObject | None:
    if not path.exists():
        return None
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        logger.warning("SS_ADMIN_TOKEN_READ_FAILED", extra={"path": str(path), "error": str(e)})
        raise AdminStoreIOError(operation="read_token", path=str(path)) from e
    if not isinstance(raw, dict):
        logger.warning("SS_ADMIN_TOKEN_INVALID", extra={"path": str(path), "reason": "not_object"})
        raise AdminStoreIOError(operation="read_token_invalid", path=str(path))
    payload = cast(JsonObject, raw)
    if str(payload.get("token_id", "")).strip() != token_id:
        logger.warning("SS_ADMIN_TOKEN_INVALID", extra={"path": str(path), "reason": "id_mismatch"})
        raise AdminStoreIOError(operation="read_token_invalid", path=str(path))
    return payload


def _meta_from_payload(payload: JsonObject) -> AdminTokenMetadata | None:
    token_id = payload.get("token_id")
    name = payload.get("name")
    created_at = payload.get("created_at")
    if not isinstance(token_id, str) or token_id.strip() == "":
        return None
    if not isinstance(name, str):
        name = ""
    if not isinstance(created_at, str) or created_at.strip() == "":
        return None
    last_used_at = payload.get("last_used_at")
    revoked_at = payload.get("revoked_at")
    return AdminTokenMetadata(
        token_id=token_id,
        name=name,
        created_at=created_at,
        last_used_at=last_used_at if isinstance(last_used_at, str) else None,
        revoked_at=revoked_at if isinstance(revoked_at, str) else None,
    )


def _load_token_meta(*, path: Path) -> AdminTokenMetadata | None:
    token_id = path.stem
    payload = _load_token_payload(path=path, token_id=token_id)
    if payload is None:
        return None
    return _meta_from_payload(payload)
