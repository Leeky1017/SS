from __future__ import annotations

import fcntl
import json
import logging
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path
from typing import cast

from src.domain.upload_session_id import job_id_from_upload_session_id
from src.domain.upload_session_store import UploadSessionStore
from src.domain.upload_sessions_models import UploadSessionRecord
from src.infra.exceptions import JobNotFoundError
from src.infra.file_queue_records import atomic_write_json
from src.infra.upload_session_exceptions import (
    UploadSessionCorruptedError,
    UploadSessionNotFoundError,
)
from src.utils.job_workspace import resolve_job_dir
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


class FileUploadSessionStore(UploadSessionStore):
    def __init__(self, *, jobs_dir: Path):
        self._jobs_dir = Path(jobs_dir)

    @contextmanager
    def lock_job(self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str):
        job_dir = resolve_job_dir(jobs_dir=self._jobs_dir, tenant_id=tenant_id, job_id=job_id)
        if job_dir is None or not (job_dir / "job.json").exists():
            raise JobNotFoundError(job_id=job_id)
        lock_path = job_dir / "inputs" / "upload_sessions.lock"
        lock_path.parent.mkdir(parents=True, exist_ok=True)
        with lock_path.open("a+", encoding="utf-8") as lock_file:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
            yield

    def _session_path(
        self,
        *,
        tenant_id: str,
        upload_session_id: str,
    ) -> Path:
        try:
            job_id = job_id_from_upload_session_id(upload_session_id)
        except ValueError as exc:
            raise UploadSessionNotFoundError(upload_session_id=upload_session_id) from exc
        job_dir = resolve_job_dir(jobs_dir=self._jobs_dir, tenant_id=tenant_id, job_id=job_id)
        if job_dir is None:
            raise UploadSessionNotFoundError(upload_session_id=upload_session_id)
        return job_dir / "inputs" / "upload_sessions" / f"{upload_session_id}.json"

    def _read_session_payload(self, *, path: Path, upload_session_id: str) -> UploadSessionRecord:
        payload = cast(JsonObject, json.loads(path.read_text(encoding="utf-8")))
        return UploadSessionRecord.from_payload(
            upload_session_id=upload_session_id,
            payload=payload,
        )

    def count_active_sessions(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        now: datetime,
    ) -> int:
        job_dir = resolve_job_dir(jobs_dir=self._jobs_dir, tenant_id=tenant_id, job_id=job_id)
        if job_dir is None:
            return 0
        sessions_dir = job_dir / "inputs" / "upload_sessions"
        if not sessions_dir.exists():
            return 0
        active = 0
        for path in sessions_dir.glob("usv1.*.json"):
            upload_session_id = path.stem
            try:
                session = self._read_session_payload(path=path, upload_session_id=upload_session_id)
            except (OSError, ValueError, UploadSessionCorruptedError):
                logger.warning(
                    "SS_UPLOAD_SESSION_STORE_READ_FAILED",
                    extra={"tenant_id": tenant_id, "job_id": job_id, "path": str(path)},
                )
                continue
            if session.finalized is not None:
                continue
            try:
                expires_at = datetime.fromisoformat(session.expires_at)
            except ValueError:
                continue
            if expires_at <= now:
                continue
            active += 1
        return active

    def load_session(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        upload_session_id: str,
    ) -> UploadSessionRecord:
        path = self._session_path(tenant_id=tenant_id, upload_session_id=upload_session_id)
        if not path.exists():
            raise UploadSessionNotFoundError(upload_session_id=upload_session_id)
        try:
            return self._read_session_payload(path=path, upload_session_id=upload_session_id)
        except FileNotFoundError as exc:
            raise UploadSessionNotFoundError(upload_session_id=upload_session_id) from exc

    def save_session(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        session: UploadSessionRecord,
    ) -> None:
        job_dir = resolve_job_dir(jobs_dir=self._jobs_dir, tenant_id=tenant_id, job_id=job_id)
        if job_dir is None:
            raise UploadSessionNotFoundError(upload_session_id=session.upload_session_id)
        sessions_dir = job_dir / "inputs" / "upload_sessions"
        sessions_dir.mkdir(parents=True, exist_ok=True)
        path = sessions_dir / f"{session.upload_session_id}.json"
        atomic_write_json(path=path, payload=session.to_payload())
