from __future__ import annotations

import hashlib
import json
import logging
import secrets
import uuid
from datetime import datetime
from pathlib import Path
from typing import cast

from src.domain.task_code_store import TaskCodeRecord, TaskCodeStore
from src.infra.atomic_write import atomic_write_json
from src.infra.auth_exceptions import TaskCodeRedeemConflictError
from src.infra.task_code_store_exceptions import (
    TaskCodeDataCorruptedError,
    TaskCodeNotFoundError,
    TaskCodeStoreIOError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


class FileTaskCodeStore(TaskCodeStore):
    def __init__(self, *, data_dir: Path):
        base = Path(data_dir) / "task_codes"
        self._records_dir = base / "records"
        self._by_hash_dir = base / "by_hash"

    def issue_codes(
        self,
        *,
        tenant_id: str,
        count: int,
        expires_at: datetime,
        now: datetime,
    ) -> list[TaskCodeRecord]:
        resolved_tenant_id = DEFAULT_TENANT_ID if tenant_id.strip() == "" else tenant_id
        if count < 1:
            return []
        issued: list[TaskCodeRecord] = []
        for _ in range(count):
            record = self._issue_one(tenant_id=resolved_tenant_id, expires_at=expires_at, now=now)
            issued.append(record)
        return issued

    def list_codes(self, *, tenant_id: str | None = None) -> list[TaskCodeRecord]:
        items: list[TaskCodeRecord] = []
        for path in self._iter_record_files():
            record = _load_record_best_effort(path=path)
            if record is None:
                continue
            if tenant_id is not None and record.tenant_id != tenant_id:
                continue
            items.append(record)
        items.sort(key=lambda item: item.created_at, reverse=True)
        return items

    def find_by_code(self, *, tenant_id: str, task_code: str) -> TaskCodeRecord | None:
        resolved_tenant_id = DEFAULT_TENANT_ID if tenant_id.strip() == "" else tenant_id
        code_hash = _code_hash(tenant_id=resolved_tenant_id, task_code=task_code)
        index_path = self._by_hash_dir / f"{code_hash}.json"
        if not index_path.exists():
            return None
        index_payload = _load_json_object(path=index_path, operation="read_index")
        code_id = str(index_payload.get("code_id", "")).strip()
        if code_id == "":
            raise TaskCodeDataCorruptedError(path=str(index_path))
        record = self.get(code_id=code_id)
        if record is None:
            return None
        if record.tenant_id != resolved_tenant_id:
            return None
        return record

    def get(self, *, code_id: str) -> TaskCodeRecord | None:
        path = self._record_path(code_id=code_id)
        if not path.exists():
            return None
        return _load_record_or_raise(path=path)

    def mark_used(self, *, code_id: str, job_id: str, used_at: datetime) -> TaskCodeRecord:
        path = self._record_path(code_id=code_id)
        payload = _load_json_object(path=path, operation="read_record")
        record = _record_from_payload(payload, path=str(path))
        if record.used_at is not None and record.used_at.strip() != "":
            if record.job_id == job_id:
                return record
            raise TaskCodeRedeemConflictError()
        payload["used_at"] = used_at.isoformat()
        payload["job_id"] = job_id
        try:
            atomic_write_json(path=path, payload=payload)
        except OSError as e:
            logger.warning(
                "SS_TASK_CODE_MARK_USED_FAILED",
                extra={"path": str(path), "error": str(e)},
            )
            raise TaskCodeStoreIOError(operation="mark_used", path=str(path)) from e
        return _record_from_payload(payload, path=str(path))

    def revoke(self, *, code_id: str, revoked_at: datetime) -> TaskCodeRecord:
        path = self._record_path(code_id=code_id)
        payload = _load_json_object(path=path, operation="read_record")
        payload["revoked_at"] = revoked_at.isoformat()
        try:
            atomic_write_json(path=path, payload=payload)
        except OSError as e:
            logger.warning(
                "SS_TASK_CODE_REVOKE_FAILED",
                extra={"path": str(path), "error": str(e)},
            )
            raise TaskCodeStoreIOError(operation="revoke", path=str(path)) from e
        return _record_from_payload(payload, path=str(path))

    def delete(self, *, code_id: str) -> None:
        record = self.get(code_id=code_id)
        if record is None:
            raise TaskCodeNotFoundError(code_id=code_id)
        record_path = self._record_path(code_id=code_id)
        index_path = (
            self._by_hash_dir
            / f"{_code_hash(tenant_id=record.tenant_id, task_code=record.task_code)}.json"
        )
        try:
            record_path.unlink(missing_ok=True)
            index_path.unlink(missing_ok=True)
        except OSError as e:
            logger.warning(
                "SS_TASK_CODE_DELETE_FAILED",
                extra={
                    "record_path": str(record_path),
                    "index_path": str(index_path),
                    "error": str(e),
                },
            )
            raise TaskCodeStoreIOError(operation="delete", path=str(record_path)) from e

    def _issue_one(
        self, *, tenant_id: str, expires_at: datetime, now: datetime
    ) -> TaskCodeRecord:
        code_id = uuid.uuid4().hex
        task_code = _new_task_code()
        created_at = now.isoformat()
        record_payload: JsonObject = {
            "code_id": code_id,
            "task_code": task_code,
            "tenant_id": tenant_id,
            "created_at": created_at,
            "expires_at": expires_at.isoformat(),
            "used_at": None,
            "job_id": None,
            "revoked_at": None,
        }
        record_path = self._record_path(code_id=code_id)
        index_path = (
            self._by_hash_dir / f"{_code_hash(tenant_id=tenant_id, task_code=task_code)}.json"
        )
        index_payload: JsonObject = {"code_id": code_id}
        try:
            atomic_write_json(path=record_path, payload=record_payload)
            atomic_write_json(path=index_path, payload=index_payload)
        except OSError as e:
            logger.warning(
                "SS_TASK_CODE_ISSUE_FAILED",
                extra={
                    "record_path": str(record_path),
                    "index_path": str(index_path),
                    "error": str(e),
                },
            )
            raise TaskCodeStoreIOError(operation="issue", path=str(record_path)) from e
        return _record_from_payload(record_payload, path=str(record_path))

    def _record_path(self, *, code_id: str) -> Path:
        return self._records_dir / f"{code_id}.json"

    def _iter_record_files(self) -> list[Path]:
        if not self._records_dir.is_dir():
            return []
        try:
            return [p for p in self._records_dir.iterdir() if p.is_file() and p.suffix == ".json"]
        except OSError as e:
            logger.warning(
                "SS_TASK_CODE_LIST_FAILED",
                extra={"dir": str(self._records_dir), "error": str(e)},
            )
            return []


def _new_task_code() -> str:
    return f"tc_{secrets.token_hex(8)}"


def _code_hash(*, tenant_id: str, task_code: str) -> str:
    payload = f"{tenant_id}:{task_code}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def _load_json_object(*, path: Path, operation: str) -> JsonObject:
    if not path.exists():
        if operation in {"read_record", "read_index"}:
            raise TaskCodeNotFoundError(code_id=path.stem)
        raise TaskCodeStoreIOError(operation=operation, path=str(path))
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        logger.warning("SS_TASK_CODE_READ_FAILED", extra={"path": str(path), "error": str(e)})
        raise TaskCodeStoreIOError(operation=operation, path=str(path)) from e
    if not isinstance(raw, dict):
        raise TaskCodeDataCorruptedError(path=str(path))
    return cast(JsonObject, raw)


def _record_from_payload(payload: JsonObject, *, path: str) -> TaskCodeRecord:
    code_id = payload.get("code_id")
    task_code = payload.get("task_code")
    tenant_id = payload.get("tenant_id")
    created_at = payload.get("created_at")
    expires_at = payload.get("expires_at")
    if not isinstance(code_id, str) or code_id.strip() == "":
        raise TaskCodeDataCorruptedError(path=path)
    if not isinstance(task_code, str) or task_code.strip() == "":
        raise TaskCodeDataCorruptedError(path=path)
    if not isinstance(tenant_id, str) or tenant_id.strip() == "":
        raise TaskCodeDataCorruptedError(path=path)
    if not isinstance(created_at, str) or created_at.strip() == "":
        raise TaskCodeDataCorruptedError(path=path)
    if not isinstance(expires_at, str) or expires_at.strip() == "":
        raise TaskCodeDataCorruptedError(path=path)
    used_at = payload.get("used_at")
    job_id = payload.get("job_id")
    revoked_at = payload.get("revoked_at")
    return TaskCodeRecord(
        code_id=code_id,
        task_code=task_code,
        tenant_id=tenant_id,
        created_at=created_at,
        expires_at=expires_at,
        used_at=used_at if isinstance(used_at, str) else None,
        job_id=job_id if isinstance(job_id, str) else None,
        revoked_at=revoked_at if isinstance(revoked_at, str) else None,
    )


def _load_record_or_raise(*, path: Path) -> TaskCodeRecord:
    payload = _load_json_object(path=path, operation="read_record")
    return _record_from_payload(payload, path=str(path))


def _load_record_best_effort(*, path: Path) -> TaskCodeRecord | None:
    try:
        return _load_record_or_raise(path=path)
    except (TaskCodeStoreIOError, TaskCodeDataCorruptedError, TaskCodeNotFoundError):
        return None
