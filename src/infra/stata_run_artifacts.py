from __future__ import annotations

import json
from pathlib import Path
from typing import Sequence

from src.domain.models import ArtifactKind, ArtifactRef
from src.domain.stata_runner import RunError, RunResult
from src.infra.stata_run_exec import Execution, read_stata_log_text
from src.infra.stata_run_filenames import (
    ERROR_FILENAME,
    META_FILENAME,
    STATA_LOG_FILENAME,
    STDERR_FILENAME,
    STDOUT_FILENAME,
)
from src.infra.stata_run_paths import job_rel_path
from src.utils.json_types import JsonObject


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_json(path: Path, payload: JsonObject) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
    path.write_text(data, encoding="utf-8")


def result_without_artifacts(
    *,
    job_id: str,
    run_id: str,
    error_code: str,
    message: str,
) -> RunResult:
    return RunResult(
        job_id=job_id,
        run_id=run_id,
        ok=False,
        exit_code=None,
        timed_out=False,
        artifacts=tuple(),
        error=RunError(error_code=error_code, message=message),
    )


def meta_payload(
    *,
    job_id: str,
    run_id: str,
    cmd: Sequence[str],
    cwd_rel: str,
    timeout_seconds: int | None,
    execution: Execution,
) -> JsonObject:
    payload: JsonObject = {
        "job_id": job_id,
        "run_id": run_id,
        "ok": execution.error is None,
        "timed_out": execution.timed_out,
        "exit_code": execution.exit_code,
        "duration_ms": execution.duration_ms,
        "timeout_seconds": timeout_seconds,
        "command": list(cmd),
        "cwd_rel": cwd_rel,
    }
    if execution.error is not None:
        error_payload: JsonObject = {
            "error_code": execution.error.error_code,
            "message": execution.error.message,
        }
        if execution.error.details is not None:
            error_payload["details"] = execution.error.details
        payload["error"] = error_payload
    return payload


def write_run_artifacts(
    *,
    artifacts_dir: Path,
    stdout_text: str,
    stderr_text: str,
    meta: JsonObject,
    error: RunError | None,
    exit_code: int | None,
    timed_out: bool,
) -> tuple[Path, Path, Path, Path, Path]:
    stdout_path = artifacts_dir / STDOUT_FILENAME
    stderr_path = artifacts_dir / STDERR_FILENAME
    log_path = artifacts_dir / STATA_LOG_FILENAME
    meta_path = artifacts_dir / META_FILENAME
    error_path = artifacts_dir / ERROR_FILENAME

    write_text(stdout_path, stdout_text)
    write_text(stderr_path, stderr_text)
    work_log_text = read_stata_log_text(cwd=artifacts_dir.parent / "work")
    if work_log_text != "":
        write_text(log_path, work_log_text)
    else:
        combined = stdout_text
        if stderr_text != "":
            combined = combined + "\n\n[stderr]\n" + stderr_text
        write_text(log_path, combined)
    write_json(meta_path, meta)
    if error is not None:
        payload: JsonObject = {
            "error_code": error.error_code,
            "message": error.message,
            "timed_out": timed_out,
            "exit_code": exit_code,
        }
        if error.details is not None:
            payload["details"] = error.details
        write_json(error_path, payload)
    return stdout_path, stderr_path, log_path, meta_path, error_path


def artifact_refs(
    *,
    job_dir: Path,
    do_artifact_path: Path,
    stdout_path: Path,
    stderr_path: Path,
    log_path: Path,
    meta_path: Path,
    error_path: Path,
    include_error: bool,
) -> tuple[ArtifactRef, ...]:
    refs: tuple[ArtifactRef, ...] = (
        ArtifactRef(
            kind=ArtifactKind.STATA_DO,
            rel_path=job_rel_path(job_dir=job_dir, path=do_artifact_path),
        ),
        ArtifactRef(
            kind=ArtifactKind.RUN_STDOUT,
            rel_path=job_rel_path(job_dir=job_dir, path=stdout_path),
        ),
        ArtifactRef(
            kind=ArtifactKind.RUN_STDERR,
            rel_path=job_rel_path(job_dir=job_dir, path=stderr_path),
        ),
        ArtifactRef(
            kind=ArtifactKind.STATA_LOG,
            rel_path=job_rel_path(job_dir=job_dir, path=log_path),
        ),
        ArtifactRef(
            kind=ArtifactKind.RUN_META_JSON,
            rel_path=job_rel_path(job_dir=job_dir, path=meta_path),
        ),
    )
    if not include_error:
        return refs
    return (
        *refs,
        ArtifactRef(
            kind=ArtifactKind.RUN_ERROR_JSON,
            rel_path=job_rel_path(job_dir=job_dir, path=error_path),
        ),
    )
