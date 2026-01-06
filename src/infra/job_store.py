from __future__ import annotations

import json
import logging
import os
import tempfile
from pathlib import Path

from src.domain.models import Draft, Job
from src.infra.exceptions import (
    JobAlreadyExistsError,
    JobDataCorruptedError,
    JobNotFoundError,
    JobStoreIOError,
)

logger = logging.getLogger(__name__)


class JobStore:
    """File-based job store: jobs/<job_id>/job.json with atomic writes."""

    def __init__(self, *, jobs_dir: Path):
        self._jobs_dir = Path(jobs_dir)

    def _job_dir(self, job_id: str) -> Path:
        return self._jobs_dir / job_id

    def _job_path(self, job_id: str) -> Path:
        return self._job_dir(job_id) / "job.json"

    def create(self, job: Job) -> None:
        path = self._job_path(job.job_id)
        if path.exists():
            raise JobAlreadyExistsError(job_id=job.job_id)
        self._job_dir(job.job_id).mkdir(parents=True, exist_ok=True)
        try:
            self._atomic_write(path, job.model_dump(mode="json"))
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
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            logger.warning("SS_JOB_JSON_CORRUPTED", extra={"job_id": job_id, "path": str(path)})
            raise JobDataCorruptedError(job_id=job_id) from e
        except OSError as e:
            logger.warning("SS_JOB_JSON_READ_FAILED", extra={"job_id": job_id, "path": str(path)})
            raise JobStoreIOError(operation="read", job_id=job_id) from e
        return Job.model_validate(raw)

    def save(self, job: Job) -> None:
        path = self._job_path(job.job_id)
        if not path.exists():
            raise JobNotFoundError(job_id=job.job_id)
        try:
            self._atomic_write(path, job.model_dump(mode="json"))
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

    def _atomic_write(self, path: Path, payload: dict) -> None:
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
