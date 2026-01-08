from __future__ import annotations

import json
import logging
from collections.abc import Mapping
from datetime import datetime
from pathlib import Path
from typing import Callable, cast

from src.domain.composition_executor import execute_composition_plan as execute_composition_plan
from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import ArtifactKind, ArtifactRef, Job, PlanStep, PlanStepType
from src.domain.stata_runner import RunError, RunResult, StataRunner
from src.infra.exceptions import DoFileInputsManifestInvalidError as InputsManifestInvalid
from src.infra.exceptions import DoFilePlanInvalidError as PlanInvalid
from src.infra.exceptions import DoFileTemplateUnsupportedError as TemplateUnsupported
from src.infra.stata_run_support import (
    Execution,
    RunDirs,
    job_rel_path,
    meta_payload,
    resolve_run_dirs,
    write_run_artifacts,
)
from src.utils.json_types import JsonValue

logger = logging.getLogger(__name__)


def execute_plan(
    *,
    job: Job,
    run_id: str,
    jobs_dir: Path,
    runner: StataRunner,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
    do_file_generator: DoFileGenerator | None = None,
) -> RunResult:
    dirs_or_error = _resolve_run_dirs_or_error(jobs_dir=jobs_dir, job=job, run_id=run_id)
    if isinstance(dirs_or_error, RunResult):
        return dirs_or_error
    dirs = dirs_or_error

    if job.llm_plan is None:
        logger.warning("SS_WORKER_PLAN_MISSING", extra={"job_id": job.job_id, "run_id": run_id})
        return _write_pre_run_error(
            dirs=dirs,
            job_id=job.job_id,
            run_id=run_id,
            error=RunError(error_code="PLAN_MISSING", message="job missing llm_plan"),
        )

    inputs_manifest = _inputs_manifest_or_error(job=job, job_dir=dirs.job_dir)
    if isinstance(inputs_manifest, RunError):
        logger.warning(
            "SS_WORKER_INPUTS_MANIFEST_FAILED",
            extra={
                "job_id": job.job_id,
                "run_id": run_id,
                "error_code": inputs_manifest.error_code,
            },
        )
        return _write_pre_run_error(
            dirs=dirs,
            job_id=job.job_id,
            run_id=run_id,
            error=inputs_manifest,
        )

    generator = DoFileGenerator() if do_file_generator is None else do_file_generator
    run_step = _find_run_step(job=job)
    if run_step is None:
        return execute_composition_plan(
            job=job,
            run_id=run_id,
            jobs_dir=Path(jobs_dir),
            runner=runner,
            inputs_manifest=inputs_manifest,
            shutdown_deadline=shutdown_deadline,
            clock=clock,
            do_file_generator=generator,
        )

    do_file = _do_file_or_error(
        generator=generator, job=job, run_id=run_id, inputs_manifest=inputs_manifest
    )
    if isinstance(do_file, RunError):
        return _write_pre_run_error(dirs=dirs, job_id=job.job_id, run_id=run_id, error=do_file)

    timeout_seconds = _timeout_seconds(step=run_step)
    effective_timeout_seconds = _cap_timeout_seconds(
        timeout_seconds=timeout_seconds,
        shutdown_deadline=shutdown_deadline,
        clock=clock,
    )
    return runner.run(
        tenant_id=job.tenant_id,
        job_id=job.job_id,
        run_id=run_id,
        do_file=do_file,
        timeout_seconds=effective_timeout_seconds,
    )


def _resolve_run_dirs_or_error(*, jobs_dir: Path, job: Job, run_id: str) -> RunDirs | RunResult:
    dirs = resolve_run_dirs(
        jobs_dir=Path(jobs_dir),
        tenant_id=job.tenant_id,
        job_id=job.job_id,
        run_id=run_id,
    )
    if dirs is not None:
        return dirs
    logger.warning(
        "SS_WORKER_RUN_DIRS_INVALID",
        extra={"tenant_id": job.tenant_id, "job_id": job.job_id, "run_id": run_id},
    )
    return RunResult(
        job_id=job.job_id,
        run_id=run_id,
        ok=False,
        exit_code=None,
        timed_out=False,
        artifacts=tuple(),
        error=RunError(error_code="STATA_WORKSPACE_INVALID", message="invalid job/run workspace"),
    )


def _find_run_step(*, job: Job) -> PlanStep | None:
    if job.llm_plan is None:
        return None
    for step in job.llm_plan.steps:
        if step.type == PlanStepType.RUN_STATA:
            return step
    return None


def _inputs_manifest_or_error(*, job: Job, job_dir: Path) -> dict[str, JsonValue] | RunError:
    if job.inputs is None:
        return RunError(error_code="INPUTS_MANIFEST_MISSING", message="job missing inputs")
    manifest_rel_path = job.inputs.manifest_rel_path
    if manifest_rel_path is None or manifest_rel_path.strip() == "":
        return RunError(
            error_code="INPUTS_MANIFEST_MISSING",
            message="job missing inputs.manifest_rel_path",
        )

    base = job_dir.resolve(strict=False)
    path = (job_dir / manifest_rel_path).resolve(strict=False)
    if not path.is_relative_to(base):
        return RunError(
            error_code="INPUTS_MANIFEST_UNSAFE",
            message="inputs manifest path escapes job workspace",
        )

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
        return RunError(
            error_code="INPUTS_MANIFEST_READ_FAILED",
            message=str(e),
        )

    if not isinstance(raw, dict):
        return RunError(
            error_code="INPUTS_MANIFEST_INVALID",
            message="inputs manifest must be a JSON object",
        )
    return cast(dict[str, JsonValue], raw)


def _do_file_or_error(
    *,
    generator: DoFileGenerator,
    job: Job,
    run_id: str,
    inputs_manifest: Mapping[str, object],
) -> str | RunError:
    if job.llm_plan is None:
        return RunError(error_code="PLAN_MISSING", message="job missing llm_plan")
    try:
        return generator.generate(plan=job.llm_plan, inputs_manifest=inputs_manifest).do_file
    except (PlanInvalid, TemplateUnsupported, InputsManifestInvalid) as e:
        logger.warning(
            "SS_WORKER_DOFILE_GENERATION_FAILED",
            extra={
                "job_id": job.job_id,
                "run_id": run_id,
                "plan_id": job.llm_plan.plan_id,
                "error_code": e.error_code,
            },
        )
        return RunError(error_code=e.error_code, message=e.message)


def _write_pre_run_error(*, dirs: RunDirs, job_id: str, run_id: str, error: RunError) -> RunResult:
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
    try:
        stdout_path, stderr_path, log_path, meta_path, error_path = write_run_artifacts(
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


def _artifact_ref(*, job_dir: Path, kind: ArtifactKind, path: Path) -> ArtifactRef:
    return ArtifactRef(kind=kind, rel_path=job_rel_path(job_dir=job_dir, path=path))


def _timeout_seconds(*, step: PlanStep) -> int | None:
    raw = step.params.get("timeout_seconds")
    if raw is None:
        return None
    if isinstance(raw, (dict, list)):
        return None
    try:
        seconds = int(raw)
    except (TypeError, ValueError):
        return None
    if seconds <= 0:
        return None
    return seconds


def _cap_timeout_seconds(
    *,
    timeout_seconds: int | None,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
) -> int | None:
    if shutdown_deadline is None:
        return timeout_seconds

    remaining = int((shutdown_deadline - clock()).total_seconds())
    if remaining <= 0:
        remaining = 1

    if timeout_seconds is None:
        return remaining
    return min(timeout_seconds, remaining)
