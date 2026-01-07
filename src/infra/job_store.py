from __future__ import annotations

import fcntl
import json
import logging
import os
import tempfile
from pathlib import Path
from typing import cast

from pydantic import ValidationError

from src.domain.models import (
    JOB_SCHEMA_VERSION_CURRENT,
    Draft,
    Job,
    is_safe_job_rel_path,
)
from src.infra.exceptions import (
    ArtifactPathUnsafeError,
    JobAlreadyExistsError,
    JobDataCorruptedError,
    JobIdUnsafeError,
    JobNotFoundError,
    JobStoreIOError,
    JobVersionConflictError,
)
from src.infra.job_store_migrations import (
    assert_supported_schema_version,
    migrate_payload_to_current,
)
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


class JobStore:
    """File-based job store: jobs/<job_id>/job.json with atomic writes."""

    def __init__(self, *, jobs_dir: Path):
        self._jobs_dir = Path(jobs_dir)

    def _is_safe_job_id(self, value: str) -> bool:
        if value == "":
            return False
        if value.startswith("~"):
            return False
        if "/" in value or "\\" in value:
            return False
        return value not in {".", ".."}

    def _resolve_job_dir(self, job_id: str) -> Path:
        if not self._is_safe_job_id(job_id):
            logger.warning("SS_JOB_ID_UNSAFE", extra={"job_id": job_id, "reason": "segment"})
            raise JobIdUnsafeError(job_id=job_id)

        base = self._jobs_dir.resolve(strict=False)
        job_dir = (self._jobs_dir / job_id).resolve(strict=False)
        if not job_dir.is_relative_to(base):
            logger.warning("SS_JOB_ID_UNSAFE", extra={"job_id": job_id, "reason": "symlink_escape"})
            raise JobIdUnsafeError(job_id=job_id)

        return job_dir

    def _job_dir(self, job_id: str) -> Path:
        return self._resolve_job_dir(job_id)

    def _job_path(self, job_id: str) -> Path:
        return self._job_dir(job_id) / "job.json"

    def _job_lock_path(self, job_id: str) -> Path:
        return self._job_dir(job_id) / "job.json.lock"

    def _read_job_payload(self, *, job_id: str, path: Path) -> JsonObject:
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            logger.warning("SS_JOB_JSON_CORRUPTED", extra={"job_id": job_id, "path": str(path)})
            raise JobDataCorruptedError(job_id=job_id) from e
        except OSError as e:
            logger.warning("SS_JOB_JSON_READ_FAILED", extra={"job_id": job_id, "path": str(path)})
            raise JobStoreIOError(operation="read", job_id=job_id) from e
        if not isinstance(raw, dict):
            logger.warning(
                "SS_JOB_JSON_CORRUPTED",
                extra={"job_id": job_id, "path": str(path), "reason": "not_object"},
            )
            raise JobDataCorruptedError(job_id=job_id)
        return cast(JsonObject, raw)

    def create(self, job: Job) -> None:
        path = self._job_path(job.job_id)
        if path.exists():
            raise JobAlreadyExistsError(job_id=job.job_id)
        if job.schema_version != JOB_SCHEMA_VERSION_CURRENT:
            logger.warning(
                "SS_JOB_JSON_SCHEMA_VERSION_UNSUPPORTED",
                extra={
                    "job_id": job.job_id,
                    "path": str(path),
                    "schema_version": job.schema_version,
                    "expected_schema_version": JOB_SCHEMA_VERSION_CURRENT,
                },
            )
            raise JobDataCorruptedError(job_id=job.job_id)
        self._job_dir(job.job_id).mkdir(parents=True, exist_ok=True)
        try:
            self._atomic_write(path, cast(JsonObject, job.model_dump(mode="json")))
        except OSError as e:
            logger.warning(
                "SS_JOB_JSON_CREATE_FAILED",
                extra={"job_id": job.job_id, "path": str(path)},
            )
            raise JobStoreIOError(operation="create", job_id=job.job_id) from e

    def load(self, job_id: str) -> Job:
        path = self._job_path(job_id)
        if not path.exists():
            raise JobNotFoundError(job_id=job_id)
        payload = self._read_job_payload(job_id=job_id, path=path)
        assert_supported_schema_version(job_id=job_id, path=path, payload=payload)
        migrated = migrate_payload_to_current(job_id=job_id, path=path, payload=payload)
        try:
            job = Job.model_validate(migrated)
        except ValidationError as e:
            logger.warning(
                "SS_JOB_JSON_INVALID",
                extra={"job_id": job_id, "path": str(path), "errors": e.errors()},
            )
            raise JobDataCorruptedError(job_id=job_id) from e
        if migrated is not payload:
            try:
                self._atomic_write(path, migrated)
            except OSError as e:
                logger.warning(
                    "SS_JOB_JSON_MIGRATION_WRITE_FAILED",
                    extra={"job_id": job_id, "path": str(path)},
                )
                raise JobStoreIOError(operation="migrate_write", job_id=job_id) from e
        return job

    def save(self, job: Job) -> None:
        path = self._job_path(job.job_id)
        if not path.exists():
            raise JobNotFoundError(job_id=job.job_id)
        if job.schema_version != JOB_SCHEMA_VERSION_CURRENT:
            logger.warning(
                "SS_JOB_JSON_SCHEMA_VERSION_UNSUPPORTED",
                extra={
                    "job_id": job.job_id,
                    "path": str(path),
                    "schema_version": job.schema_version,
                    "expected_schema_version": JOB_SCHEMA_VERSION_CURRENT,
                },
            )
            raise JobDataCorruptedError(job_id=job.job_id)
        lock_path = self._job_lock_path(job.job_id)
        try:
            with lock_path.open("a+", encoding="utf-8") as lock_file:
                fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
                payload = self._read_job_payload(job_id=job.job_id, path=path)
                assert_supported_schema_version(job_id=job.job_id, path=path, payload=payload)
                current = migrate_payload_to_current(job_id=job.job_id, path=path, payload=payload)
                disk_version = current.get("version", 1)
                if not isinstance(disk_version, int) or disk_version < 1:
                    logger.warning(
                        "SS_JOB_JSON_CORRUPTED",
                        extra={
                            "job_id": job.job_id,
                            "path": str(path),
                            "reason": "version_invalid",
                        },
                    )
                    raise JobDataCorruptedError(job_id=job.job_id)
                if job.version != disk_version:
                    logger.warning(
                        "SS_JOB_JSON_VERSION_CONFLICT",
                        extra={
                            "job_id": job.job_id,
                            "path": str(path),
                            "expected_version": job.version,
                            "actual_version": disk_version,
                        },
                    )
                    raise JobVersionConflictError(
                        job_id=job.job_id, expected_version=job.version, actual_version=disk_version
                    )
                new_version = disk_version + 1
                to_write = job.model_copy(update={"version": new_version})
                self._atomic_write(path, cast(JsonObject, to_write.model_dump(mode="json")))
                job.version = new_version
        except OSError as e:
            logger.warning(
                "SS_JOB_JSON_WRITE_FAILED",
                extra={"job_id": job.job_id, "path": str(path)},
            )
            raise JobStoreIOError(operation="write", job_id=job.job_id) from e

    def write_draft(self, *, job_id: str, draft: Draft) -> None:
        job = self.load(job_id)
        job.draft = draft
        self.save(job)

    def write_artifact_json(self, *, job_id: str, rel_path: str, payload: JsonObject) -> None:
        if not is_safe_job_rel_path(rel_path):
            logger.warning(
                "SS_JOB_ARTIFACT_PATH_UNSAFE",
                extra={"job_id": job_id, "rel_path": rel_path, "reason": "unsafe_rel_path"},
            )
            raise ArtifactPathUnsafeError(job_id=job_id, rel_path=rel_path)

        job_dir = self._job_dir(job_id)
        if not job_dir.exists():
            raise JobNotFoundError(job_id=job_id)

        path = (job_dir / rel_path).resolve(strict=False)
        if not path.is_relative_to(job_dir):
            logger.warning(
                "SS_JOB_ARTIFACT_PATH_UNSAFE",
                extra={"job_id": job_id, "rel_path": rel_path, "reason": "symlink_escape"},
            )
            raise ArtifactPathUnsafeError(job_id=job_id, rel_path=rel_path)
        try:
            self._atomic_write(path, payload)
        except OSError as e:
            logger.warning(
                "SS_JOB_ARTIFACT_JSON_WRITE_FAILED",
                extra={"job_id": job_id, "path": str(path)},
            )
            raise JobStoreIOError(operation="artifact_write", job_id=job_id) from e

    def _atomic_write(self, path: Path, payload: JsonObject) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
        with tempfile.NamedTemporaryFile(
            "w",
            encoding="utf-8",
            dir=str(path.parent),
            delete=False,
        ) as f:
            f.write(data)
            tmp = Path(f.name)
        os.replace(tmp, path)
