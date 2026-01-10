from __future__ import annotations

import logging
from pathlib import Path

from src.domain.models import ArtifactKind, ArtifactRef
from src.domain.stata_runner import RunError, RunResult
from src.infra.stata_run_support import (
    Execution,
    RunDirs,
    job_rel_path,
    meta_payload,
    write_run_artifacts,
)
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


def _artifact_ref(*, job_dir: Path, kind: ArtifactKind, path: Path) -> ArtifactRef:
    return ArtifactRef(kind=kind, rel_path=job_rel_path(job_dir=job_dir, path=path))


def _execution_and_meta(
    *,
    dirs: RunDirs,
    job_id: str,
    run_id: str,
    error: RunError,
) -> tuple[Execution, JsonObject]:
    execution = Execution(
        stdout_text="",
        stderr_text=error.message,
        exit_code=None,
        timed_out=False,
        duration_ms=0,
        error=error,
    )
    meta = meta_payload(
        job_id=job_id,
        run_id=run_id,
        cmd=["ss-worker", "pre-run"],
        cwd_rel=job_rel_path(job_dir=dirs.job_dir, path=dirs.work_dir),
        timeout_seconds=None,
        execution=execution,
    )
    return execution, meta


def _write_artifacts_or_error(
    *,
    dirs: RunDirs,
    job_id: str,
    run_id: str,
    execution: Execution,
    meta: JsonObject,
    error: RunError,
) -> tuple[Path, Path, Path, Path, Path] | RunResult:
    try:
        return write_run_artifacts(
            artifacts_dir=dirs.artifacts_dir,
            stdout_text=execution.stdout_text,
            stderr_text=execution.stderr_text,
            meta=meta,
            error=error,
            exit_code=execution.exit_code,
            timed_out=execution.timed_out,
        )
    except OSError as e:
        logger.warning(
            "SS_WORKER_PRE_RUN_ARTIFACTS_WRITE_FAILED",
            extra={"job_id": job_id, "run_id": run_id, "reason": str(e)},
        )
        return RunResult(
            job_id=job_id,
            run_id=run_id,
            ok=False,
            exit_code=None,
            timed_out=False,
            artifacts=tuple(),
            error=RunError(error_code="WORKER_ARTIFACTS_WRITE_FAILED", message=str(e)),
        )


def write_pre_run_error(*, dirs: RunDirs, job_id: str, run_id: str, error: RunError) -> RunResult:
    dirs.work_dir.mkdir(parents=True, exist_ok=True)
    dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)
    execution, meta = _execution_and_meta(dirs=dirs, job_id=job_id, run_id=run_id, error=error)
    written = _write_artifacts_or_error(
        dirs=dirs,
        job_id=job_id,
        run_id=run_id,
        execution=execution,
        meta=meta,
        error=error,
    )
    if isinstance(written, RunResult):
        return written
    stdout_path, stderr_path, log_path, meta_path, error_path = written
    artifacts = (
        _artifact_ref(job_dir=dirs.job_dir, kind=ArtifactKind.RUN_STDOUT, path=stdout_path),
        _artifact_ref(job_dir=dirs.job_dir, kind=ArtifactKind.RUN_STDERR, path=stderr_path),
        _artifact_ref(job_dir=dirs.job_dir, kind=ArtifactKind.STATA_LOG, path=log_path),
        _artifact_ref(job_dir=dirs.job_dir, kind=ArtifactKind.RUN_META_JSON, path=meta_path),
        _artifact_ref(job_dir=dirs.job_dir, kind=ArtifactKind.RUN_ERROR_JSON, path=error_path),
    )
    return RunResult(
        job_id=job_id,
        run_id=run_id,
        ok=False,
        exit_code=None,
        timed_out=False,
        artifacts=artifacts,
        error=error,
    )
