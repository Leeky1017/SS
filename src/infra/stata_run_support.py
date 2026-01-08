from __future__ import annotations

import json
import re
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Sequence, cast

from src.domain.models import ArtifactKind, ArtifactRef
from src.domain.stata_runner import RunError, RunResult
from src.utils.job_workspace import resolve_job_dir
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

DO_FILENAME = "stata.do"
STDOUT_FILENAME = "run.stdout"
STDERR_FILENAME = "run.stderr"
STATA_LOG_FILENAME = "stata.log"
META_FILENAME = "run.meta.json"
ERROR_FILENAME = "run.error.json"

_STATA_RETURN_CODE_RE = re.compile(r"^\s*r\((?P<code>\d+)\);", re.MULTILINE)


@dataclass(frozen=True)
class RunDirs:
    job_dir: Path
    run_dir: Path
    work_dir: Path
    artifacts_dir: Path


@dataclass(frozen=True)
class Execution:
    stdout_text: str
    stderr_text: str
    exit_code: int | None
    timed_out: bool
    duration_ms: int
    error: RunError | None


def safe_segment(value: str) -> bool:
    if value == "":
        return False
    if "/" in value or "\\" in value:
        return False
    if value in {".", ".."}:
        return False
    return True


def job_rel_path(*, job_dir: Path, path: Path) -> str:
    return path.relative_to(job_dir).as_posix()


def resolve_run_dirs(
    *,
    jobs_dir: Path,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
    run_id: str,
) -> RunDirs | None:
    if not safe_segment(job_id) or not safe_segment(run_id):
        return None

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, tenant_id=tenant_id, job_id=job_id)
    if job_dir is None:
        return None

    run_dir = (job_dir / "runs" / run_id).resolve()
    if not run_dir.is_relative_to(job_dir):
        return None

    work_dir = (run_dir / "work").resolve(strict=False)
    if not work_dir.is_relative_to(run_dir):
        return None

    artifacts_dir = (run_dir / "artifacts").resolve(strict=False)
    if not artifacts_dir.is_relative_to(run_dir):
        return None
    return RunDirs(job_dir=job_dir, run_dir=run_dir, work_dir=work_dir, artifacts_dir=artifacts_dir)


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_json(path: Path, payload: JsonObject) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
    path.write_text(data, encoding="utf-8")


def coerce_text(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def _extract_stata_return_code_error(*, log_text: str) -> RunError | None:
    last_match = None
    for match in _STATA_RETURN_CODE_RE.finditer(log_text):
        last_match = match
    if last_match is None:
        return None
    code = int(last_match.group("code"))
    if code == 0:
        return None
    return RunError("STATA_RETURN_CODE", f"stata log contains r({code});")


def _read_stata_log_text(*, cwd: Path) -> str:
    path = cwd / STATA_LOG_FILENAME
    if not path.is_file():
        return ""
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


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


def execute(
    *,
    cmd: Sequence[str],
    cwd: Path,
    timeout_seconds: int | None,
    runner: Callable[..., subprocess.CompletedProcess[str]] | None,
) -> Execution:
    started = time.time()
    try:
        run = subprocess.run if runner is None else runner
        completed = run(
            cmd,
            cwd=str(cwd),
            timeout=timeout_seconds,
            text=True,
            capture_output=True,
            check=False,
        )
        exit_code = int(completed.returncode)
        timed_out = False
        if exit_code == 0:
            log_error = _extract_stata_return_code_error(log_text=_read_stata_log_text(cwd=cwd))
            error = log_error
        else:
            error = RunError("STATA_NONZERO_EXIT", f"stata exited with code {exit_code}")
        stdout_text = coerce_text(completed.stdout)
        stderr_text = coerce_text(completed.stderr)
    except subprocess.TimeoutExpired as e:
        stdout_text = coerce_text(e.stdout)
        stderr_text = coerce_text(e.stderr)
        exit_code = None
        timed_out = True
        error = RunError("STATA_TIMEOUT", "stata execution timed out")
    except OSError as e:
        stdout_text = ""
        stderr_text = str(e)
        exit_code = None
        timed_out = False
        error = RunError("STATA_SUBPROCESS_FAILED", str(e))
    duration_ms = int((time.time() - started) * 1000)
    return Execution(
        stdout_text=stdout_text,
        stderr_text=stderr_text,
        exit_code=exit_code,
        timed_out=timed_out,
        duration_ms=duration_ms,
        error=error,
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
        payload["error"] = cast(
            JsonObject,
            {
                "error_code": execution.error.error_code,
                "message": execution.error.message,
            },
        )
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
    work_log_text = _read_stata_log_text(cwd=artifacts_dir.parent / "work")
    if work_log_text != "":
        write_text(log_path, work_log_text)
    else:
        combined = stdout_text
        if stderr_text != "":
            combined = combined + "\n\n[stderr]\n" + stderr_text
        write_text(log_path, combined)
    write_json(meta_path, meta)
    if error is not None:
        write_json(
            error_path,
            cast(
                JsonObject,
                {
                    "error_code": error.error_code,
                    "message": error.message,
                    "timed_out": timed_out,
                    "exit_code": exit_code,
                },
            ),
        )
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
