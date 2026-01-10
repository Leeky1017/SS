from __future__ import annotations

import logging
import subprocess
from pathlib import Path
from typing import Callable, Sequence

from src.domain.models import is_safe_job_rel_path
from src.domain.stata_runner import RunError, RunResult
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
from src.infra.stata_safety import copy_inputs_dir, find_unsafe_dofile_reason
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)

def _prepare_workspace(
    *,
    jobs_dir: Path,
    tenant_id: str,
    job_id: str,
    run_id: str,
    do_file: str,
    inputs_dir_rel: str | None,
) -> tuple[RunDirs, Path] | RunResult:
    dirs = resolve_run_dirs(jobs_dir=jobs_dir, tenant_id=tenant_id, job_id=job_id, run_id=run_id)
    if dirs is None:
        logger.warning(
            "SS_STATA_RUN_INVALID_WORKSPACE",
            extra={"tenant_id": tenant_id, "job_id": job_id, "run_id": run_id},
        )
        return result_without_artifacts(
            job_id=job_id,
            run_id=run_id,
            error_code="STATA_WORKSPACE_INVALID",
            message="invalid job_id/run_id workspace",
        )

    dirs.work_dir.mkdir(parents=True, exist_ok=True)
    dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)
    try:
        source_dir = _inputs_source_dir(job_dir=dirs.job_dir, inputs_dir_rel=inputs_dir_rel)
        if source_dir is None:
            return result_without_artifacts(
                job_id=job_id,
                run_id=run_id,
                error_code="STATA_INPUTS_UNSAFE",
                message="inputs_dir_rel unsafe",
            )
        copy_inputs_dir(source_dir=source_dir, work_dir=dirs.work_dir)
    except OSError as e:
        logger.warning(
            "SS_STATA_RUN_COPY_INPUTS_FAILED",
            extra={"job_id": job_id, "run_id": run_id, "reason": str(e)},
        )
        return result_without_artifacts(
            job_id=job_id,
            run_id=run_id,
            error_code="STATA_INPUTS_COPY_FAILED",
            message=str(e),
        )

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


def _inputs_source_dir(*, job_dir: Path, inputs_dir_rel: str | None) -> Path | None:
    if inputs_dir_rel is None:
        return job_dir / "inputs"
    if inputs_dir_rel.strip() == "" or not is_safe_job_rel_path(inputs_dir_rel):
        return None
    base = job_dir.resolve(strict=False)
    path = (job_dir / inputs_dir_rel).resolve(strict=False)
    if not path.is_relative_to(base):
        return None
    return path


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
    meta: JsonObject,
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
    tenant_id: str,
    job_id: str,
    run_id: str,
    do_file: str,
    stata_cmd: Sequence[str],
    timeout_seconds: int | None,
    subprocess_runner: Callable[..., subprocess.CompletedProcess[str]] | None,
    inputs_dir_rel: str | None = None,
) -> RunResult:
    prepared = _prepare_workspace(
        jobs_dir=jobs_dir,
        tenant_id=tenant_id,
        job_id=job_id,
        run_id=run_id,
        do_file=do_file,
        inputs_dir_rel=inputs_dir_rel,
    )
    if isinstance(prepared, RunResult):
        return prepared
    dirs, do_artifact_path = prepared
    unsafe_reason = find_unsafe_dofile_reason(do_file)
    if unsafe_reason is not None:
        cmd = build_stata_batch_cmd(stata_cmd=stata_cmd, do_filename=DO_FILENAME)
        logger.warning(
            "SS_STATA_DOFILE_UNSAFE",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "run_id": run_id,
                "reason": unsafe_reason,
            },
        )
        return _persist_run(
            dirs=dirs,
            job_id=job_id,
            run_id=run_id,
            do_artifact_path=do_artifact_path,
            cmd=cmd,
            timeout_seconds=timeout_seconds,
            execution=Execution(
                stdout_text="",
                stderr_text="",
                exit_code=None,
                timed_out=False,
                duration_ms=0,
                error=RunError(error_code="STATA_DOFILE_UNSAFE", message=unsafe_reason),
            ),
        )
    return _run_in_workspace(
        dirs=dirs,
        job_id=job_id,
        run_id=run_id,
        do_artifact_path=do_artifact_path,
        stata_cmd=stata_cmd,
        timeout_seconds=timeout_seconds,
        subprocess_runner=subprocess_runner,
    )
