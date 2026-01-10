from __future__ import annotations

import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Callable, cast

from src.domain.models import (
    ArtifactKind,
    ArtifactRef,
    Job,
    PlanStep,
    PlanStepType,
    is_safe_job_rel_path,
)
from src.domain.stata_runner import RunError, RunResult
from src.infra.stata_run_support import (
    ERROR_FILENAME,
    META_FILENAME,
    STATA_LOG_FILENAME,
    STDERR_FILENAME,
    STDOUT_FILENAME,
    Execution,
    RunDirs,
    job_rel_path,
    meta_payload,
    write_run_artifacts,
)
from src.utils.json_types import JsonObject, JsonValue

logger = logging.getLogger(__name__)


def artifact_ref(*, job_dir: Path, kind: ArtifactKind, path: Path) -> ArtifactRef:
    return ArtifactRef(kind=kind, rel_path=job_rel_path(job_dir=job_dir, path=path))


def inputs_manifest_or_error(*, job: Job, job_dir: Path) -> dict[str, JsonValue] | RunError:
    if job.inputs is None:
        return RunError(error_code="INPUTS_MANIFEST_MISSING", message="job missing inputs")
    manifest_rel_path = job.inputs.manifest_rel_path
    if manifest_rel_path is None or manifest_rel_path.strip() == "":
        return RunError(
            error_code="INPUTS_MANIFEST_MISSING",
            message="job missing inputs.manifest_rel_path",
        )
    if not is_safe_job_rel_path(manifest_rel_path):
        return RunError(
            error_code="INPUTS_MANIFEST_UNSAFE",
            message="inputs manifest path unsafe",
        )

    path = job_dir / manifest_rel_path
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return RunError(
            error_code="INPUTS_MANIFEST_MISSING",
            message=f"inputs manifest not found: {manifest_rel_path}",
        )
    except json.JSONDecodeError as e:
        return RunError(
            error_code="INPUTS_MANIFEST_INVALID",
            message=f"inputs manifest JSON invalid: {e}",
        )
    except OSError as e:
        return RunError(error_code="INPUTS_MANIFEST_READ_FAILED", message=str(e))
    if not isinstance(raw, dict):
        return RunError(
            error_code="INPUTS_MANIFEST_INVALID",
            message="inputs manifest must be a JSON object",
        )
    return cast(dict[str, JsonValue], raw)


def write_pre_run_error(
    *,
    dirs: RunDirs,
    job_id: str,
    run_id: str,
    error: RunError,
    extra_artifacts: tuple[ArtifactRef, ...] = tuple(),
) -> RunResult:
    dirs.work_dir.mkdir(parents=True, exist_ok=True)
    dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)
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
    written = _write_run_artifacts_or_error(dirs=dirs, meta=meta, execution=execution)
    if isinstance(written, RunResult):
        return written
    artifacts = _pre_run_error_artifacts(dirs=dirs)
    return RunResult(
        job_id=job_id,
        run_id=run_id,
        ok=False,
        exit_code=None,
        timed_out=False,
        artifacts=(*extra_artifacts, *artifacts),
        error=error,
    )


def _pre_run_error_artifacts(*, dirs: RunDirs) -> tuple[ArtifactRef, ...]:
    return (
        artifact_ref(
            job_dir=dirs.job_dir,
            kind=ArtifactKind.RUN_STDOUT,
            path=dirs.artifacts_dir / STDOUT_FILENAME,
        ),
        artifact_ref(
            job_dir=dirs.job_dir,
            kind=ArtifactKind.RUN_STDERR,
            path=dirs.artifacts_dir / STDERR_FILENAME,
        ),
        artifact_ref(
            job_dir=dirs.job_dir,
            kind=ArtifactKind.STATA_LOG,
            path=dirs.artifacts_dir / STATA_LOG_FILENAME,
        ),
        artifact_ref(
            job_dir=dirs.job_dir,
            kind=ArtifactKind.RUN_META_JSON,
            path=dirs.artifacts_dir / META_FILENAME,
        ),
        artifact_ref(
            job_dir=dirs.job_dir,
            kind=ArtifactKind.RUN_ERROR_JSON,
            path=dirs.artifacts_dir / ERROR_FILENAME,
        ),
    )


def _write_run_artifacts_or_error(
    *,
    dirs: RunDirs,
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
            "SS_WORKER_PRE_RUN_ARTIFACTS_WRITE_FAILED",
            extra={
                "job_id": meta.get("job_id", ""),
                "run_id": meta.get("run_id", ""),
                "reason": str(e),
            },
        )
        return RunResult(
            job_id=cast(str, meta.get("job_id", "")),
            run_id=cast(str, meta.get("run_id", "")),
            ok=False,
            exit_code=None,
            timed_out=False,
            artifacts=tuple(),
            error=RunError(error_code="WORKER_ARTIFACTS_WRITE_FAILED", message=str(e)),
        )


def timeout_seconds(*, step_params: dict[str, JsonValue]) -> int | None:
    raw = step_params.get("timeout_seconds")
    if raw is None or isinstance(raw, (dict, list)):
        return None
    try:
        seconds = int(raw)
    except (TypeError, ValueError):
        return None
    if seconds <= 0:
        return None
    return seconds


def failed_runner_result(
    *,
    runner_result: RunResult,
    error: RunError,
    artifacts: tuple[ArtifactRef, ...],
) -> RunResult:
    return RunResult(
        job_id=runner_result.job_id,
        run_id=runner_result.run_id,
        ok=False,
        exit_code=runner_result.exit_code,
        timed_out=runner_result.timed_out,
        artifacts=artifacts,
        error=error,
    )


def find_run_step(*, steps: list[PlanStep]) -> PlanStep | None:
    for step in steps:
        if step.type == PlanStepType.RUN_STATA:
            return step
    return None


def effective_timeout_seconds(
    *,
    step: PlanStep,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
) -> int | None:
    base = timeout_seconds(step_params=step.params)
    if shutdown_deadline is None:
        return base
    remaining = int((shutdown_deadline - clock()).total_seconds())
    if remaining <= 0:
        remaining = 1
    if base is None:
        return remaining
    return min(base, remaining)
