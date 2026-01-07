from __future__ import annotations

import logging
import os
import tempfile
from pathlib import Path

from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import is_safe_job_rel_path
from src.infra.exceptions import JobNotFoundError
from src.infra.input_exceptions import InputPathUnsafeError, InputStorageFailedError
from src.utils.job_workspace import resolve_job_dir
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


class FileJobWorkspaceStore(JobWorkspaceStore):
    def __init__(self, *, jobs_dir: Path):
        self._jobs_dir = Path(jobs_dir)

    def _job_dir(self, *, tenant_id: str, job_id: str) -> Path:
        job_dir = resolve_job_dir(jobs_dir=self._jobs_dir, tenant_id=tenant_id, job_id=job_id)
        if job_dir is None or not (job_dir / "job.json").exists():
            raise JobNotFoundError(job_id=job_id)
        return job_dir

    def write_bytes(
        self,
        *,
        job_id: str,
        rel_path: str,
        data: bytes,
        tenant_id: str = DEFAULT_TENANT_ID,
    ) -> None:
        if not is_safe_job_rel_path(rel_path):
            logger.warning(
                "SS_INPUT_PATH_UNSAFE",
                extra={"tenant_id": tenant_id, "job_id": job_id, "rel_path": rel_path},
            )
            raise InputPathUnsafeError(job_id=job_id, rel_path=rel_path)
        job_dir = self._job_dir(tenant_id=tenant_id, job_id=job_id)
        path = (job_dir / rel_path).resolve(strict=False)
        if not path.is_relative_to(job_dir):
            logger.warning(
                "SS_INPUT_PATH_UNSAFE",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "rel_path": rel_path,
                    "reason": "symlink_escape",
                },
            )
            raise InputPathUnsafeError(job_id=job_id, rel_path=rel_path)
        try:
            self._atomic_write_bytes(path, data)
        except OSError as e:
            logger.warning(
                "SS_INPUT_WRITE_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job_id, "path": str(path)},
            )
            raise InputStorageFailedError(job_id=job_id, rel_path=rel_path) from e

    def resolve_for_read(
        self,
        *,
        job_id: str,
        rel_path: str,
        tenant_id: str = DEFAULT_TENANT_ID,
    ) -> Path:
        if not is_safe_job_rel_path(rel_path):
            logger.warning(
                "SS_INPUT_PATH_UNSAFE",
                extra={"tenant_id": tenant_id, "job_id": job_id, "rel_path": rel_path},
            )
            raise InputPathUnsafeError(job_id=job_id, rel_path=rel_path)
        job_dir = self._job_dir(tenant_id=tenant_id, job_id=job_id)
        base = job_dir.resolve(strict=False)
        candidate = job_dir / rel_path
        resolved = candidate.resolve(strict=True)
        if not resolved.is_relative_to(base):
            logger.warning(
                "SS_INPUT_PATH_UNSAFE",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "rel_path": rel_path,
                    "reason": "symlink_escape",
                },
            )
            raise InputPathUnsafeError(job_id=job_id, rel_path=rel_path)
        if not resolved.is_file():
            raise FileNotFoundError(str(resolved))
        return resolved

    def _atomic_write_bytes(self, path: Path, data: bytes) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp: Path | None = None
        try:
            with tempfile.NamedTemporaryFile("wb", dir=str(path.parent), delete=False) as f:
                tmp = Path(f.name)
                f.write(data)
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp, path)
        except OSError:
            if tmp is not None:
                try:
                    tmp.unlink(missing_ok=True)
                except OSError:
                    logger.warning(
                        "SS_ATOMIC_WRITE_TMP_CLEANUP_FAILED",
                        extra={"path": str(path), "tmp": str(tmp)},
                    )
            raise

