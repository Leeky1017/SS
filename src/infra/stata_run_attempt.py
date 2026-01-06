from __future__ import annotations

import logging
import shutil
import subprocess
from pathlib import Path
from typing import Callable, Sequence

from src.domain.do_file_generator import DEFAULT_SUMMARY_TABLE_FILENAME
from src.domain.models import ArtifactKind, ArtifactRef
from src.domain.stata_runner import RunResult
from src.infra.stata_cmd import build_stata_batch_cmd
from src.infra.stata_run_support import (
    DO_FILENAME,
    Execution,
    RunDirs,
    artifact_refs,
    execute,
    job_rel_path,
    meta_payload,
    resolve_run_dirs,
    result_without_artifacts,
    write_run_artifacts,
    write_text,
)

logger = logging.getLogger(__name__)


def _collect_exported_table(*, dirs: RunDirs, job_id: str, run_id: str) -> ArtifactRef | None:
    source = dirs.work_dir / DEFAULT_SUMMARY_TABLE_FILENAME
    if not source.exists():
        return None

    dest = dirs.artifacts_dir / DEFAULT_SUMMARY_TABLE_FILENAME
    try:
        shutil.copy2(source, dest)
    except OSError as e:
        logger.warning(
            "SS_STATA_RUN_EXPORT_TABLE_COPY_FAILED",
            extra={
                "job_id": job_id,
                "run_id": run_id,
                "src": str(source),
                "dst": str(dest),
                "reason": str(e),
            },
        )
        return None

    return ArtifactRef(
        kind=ArtifactKind.STATA_EXPORT_TABLE,
        rel_path=job_rel_path(job_dir=dirs.job_dir, path=dest),
    )


def _prepare_workspace(
    *,
    jobs_dir: Path,
    job_id: str,
    run_id: str,
    do_file: str,
) -> tuple[RunDirs, Path] | RunResult:
    dirs = resolve_run_dirs(jobs_dir=jobs_dir, job_id=job_id, run_id=run_id)
    if dirs is None:
        logger.warning("SS_STATA_RUN_INVALID_WORKSPACE", extra={"job_id": job_id, "run_id": run_id})
        return result_without_artifacts(
            job_id=job_id,
            run_id=run_id,
            error_code="STATA_WORKSPACE_INVALID",
            message="invalid job_id/run_id workspace",
        )

    dirs.work_dir.mkdir(parents=True, exist_ok=True)
    dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)

    do_work_path = dirs.work_dir / DO_FILENAME
    do_artifact_path = dirs.artifacts_dir / DO_FILENAME
    try:
        write_text(do_work_path, do_file)
        write_text(do_artifact_path, do_file)
    except OSError as e:
        logger.warning(
            "SS_STATA_RUN_WRITE_DOFILE_FAILED",
            extra={"job_id": job_id, "run_id": run_id, "path": str(do_work_path)},
        )
        return result_without_artifacts(
            job_id=job_id,
            run_id=run_id,
            error_code="STATA_DOFILE_WRITE_FAILED",
            message=str(e),
        )
    return dirs, do_artifact_path


def _log_completion(*, job_id: str, run_id: str, execution: Execution) -> None:
    if execution.error is not None:
        logger.warning(
            "SS_STATA_RUN_FAILED",
            extra={
                "job_id": job_id,
                "run_id": run_id,
                "error_code": execution.error.error_code,
                "exit_code": execution.exit_code,
                "timed_out": execution.timed_out,
                "duration_ms": execution.duration_ms,
            },
        )
        return
    logger.info(
        "SS_STATA_RUN_DONE",
        extra={
            "job_id": job_id,
            "run_id": run_id,
            "exit_code": execution.exit_code,
            "duration_ms": execution.duration_ms,
        },
    )


def _write_artifacts_or_error(
    *,
    dirs: RunDirs,
    job_id: str,
    run_id: str,
    meta: dict,
    execution: Execution,
) -> tuple[Path, Path, Path, Path, Path] | RunResult:
    try:
        return write_run_artifacts(
            artifacts_dir=dirs.artifacts_dir,
            stdout_text=execution.stdout_text,
            stderr_text=execution.stderr_text,
            meta=meta,
            error=execution.error,
            exit_code=execution.exit_code,
            timed_out=execution.timed_out,
        )
    except OSError as e:
        logger.warning(
            "SS_STATA_RUN_WRITE_ARTIFACTS_FAILED",
            extra={"job_id": job_id, "run_id": run_id, "reason": str(e)},
        )
        return result_without_artifacts(
            job_id=job_id,
            run_id=run_id,
            error_code="STATA_ARTIFACTS_WRITE_FAILED",
            message=str(e),
        )


def _persist_run(
    *,
    dirs: RunDirs,
    job_id: str,
    run_id: str,
    do_artifact_path: Path,
    cmd: Sequence[str],
    timeout_seconds: int | None,
    execution: Execution,
) -> RunResult:
    meta = meta_payload(
        job_id=job_id,
        run_id=run_id,
        cmd=cmd,
        cwd_rel=job_rel_path(job_dir=dirs.job_dir, path=dirs.work_dir),
        timeout_seconds=timeout_seconds,
        execution=execution,
    )
    written = _write_artifacts_or_error(
        dirs=dirs,
        job_id=job_id,
        run_id=run_id,
        meta=meta,
        execution=execution,
    )
    if isinstance(written, RunResult):
        return written
    stdout_path, stderr_path, log_path, meta_path, error_path = written

    artifacts = artifact_refs(
        job_dir=dirs.job_dir,
        do_artifact_path=do_artifact_path,
        stdout_path=stdout_path,
        stderr_path=stderr_path,
        log_path=log_path,
        meta_path=meta_path,
        error_path=error_path,
        include_error=execution.error is not None,
    )
    export_table_ref = _collect_exported_table(dirs=dirs, job_id=job_id, run_id=run_id)
    if export_table_ref is not None:
        artifacts = (*artifacts, export_table_ref)
    _log_completion(job_id=job_id, run_id=run_id, execution=execution)
    return RunResult(
        job_id=job_id,
        run_id=run_id,
        ok=execution.error is None,
        exit_code=execution.exit_code,
        timed_out=execution.timed_out,
        artifacts=artifacts,
        error=execution.error,
    )


def _run_in_workspace(
    *,
    dirs: RunDirs,
    job_id: str,
    run_id: str,
    do_artifact_path: Path,
    stata_cmd: Sequence[str],
    timeout_seconds: int | None,
    subprocess_runner: Callable[..., subprocess.CompletedProcess[str]] | None,
) -> RunResult:
    cmd = build_stata_batch_cmd(stata_cmd=stata_cmd, do_filename=DO_FILENAME)
    logger.info(
        "SS_STATA_RUN_START",
        extra={"job_id": job_id, "run_id": run_id, "cwd": str(dirs.work_dir), "cmd": cmd},
    )

    execution = execute(
        cmd=cmd,
        cwd=dirs.work_dir,
        timeout_seconds=timeout_seconds,
        runner=subprocess_runner,
    )
    return _persist_run(
        dirs=dirs,
        job_id=job_id,
        run_id=run_id,
        do_artifact_path=do_artifact_path,
        cmd=cmd,
        timeout_seconds=timeout_seconds,
        execution=execution,
    )


def run_local_stata_attempt(
    *,
    jobs_dir: Path,
    job_id: str,
    run_id: str,
    do_file: str,
    stata_cmd: Sequence[str],
    timeout_seconds: int | None,
    subprocess_runner: Callable[..., subprocess.CompletedProcess[str]] | None,
) -> RunResult:
    prepared = _prepare_workspace(jobs_dir=jobs_dir, job_id=job_id, run_id=run_id, do_file=do_file)
    if isinstance(prepared, RunResult):
        return prepared
    dirs, do_artifact_path = prepared
    return _run_in_workspace(
        dirs=dirs,
        job_id=job_id,
        run_id=run_id,
        do_artifact_path=do_artifact_path,
        stata_cmd=stata_cmd,
        timeout_seconds=timeout_seconds,
        subprocess_runner=subprocess_runner,
    )
