from __future__ import annotations

from collections.abc import Mapping
from pathlib import Path

from src.domain.composition_exec.summary import write_pipeline_error, write_pipeline_summary
from src.domain.models import Job
from src.domain.stata_runner import RunError, RunResult
from src.infra.stata_run_support import RunDirs, resolve_run_dirs


def pipeline_dirs_or_error(*, job: Job, run_id: str, jobs_dir: Path) -> RunDirs | RunResult:
    dirs = resolve_run_dirs(
        jobs_dir=Path(jobs_dir),
        tenant_id=job.tenant_id,
        job_id=job.job_id,
        run_id=run_id,
    )
    if dirs is None:
        return _result_error(
            job_id=job.job_id,
            run_id=run_id,
            error_code="STATA_WORKSPACE_INVALID",
            message="invalid job/run workspace",
        )
    dirs.work_dir.mkdir(parents=True, exist_ok=True)
    dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)
    return dirs


def fail_pipeline(
    *,
    job: Job,
    pipeline_dirs: RunDirs,
    pipeline_run_id: str,
    inputs_manifest: Mapping[str, object],
    composition_mode: str,
    steps: list[object],
    decisions: list[object],
    error: RunError,
) -> RunResult:
    summary_ref = write_pipeline_summary(
        job=job,
        job_dir=pipeline_dirs.job_dir,
        pipeline_run_id=pipeline_run_id,
        artifacts_dir=pipeline_dirs.artifacts_dir,
        composition_mode=composition_mode,
        inputs_manifest=inputs_manifest,
        steps=list(steps),
        decisions=list(decisions),
        error={"error_code": error.error_code, "message": error.message},
    )
    result = write_pipeline_error(
        pipeline_dirs=pipeline_dirs,
        job_id=job.job_id,
        run_id=pipeline_run_id,
        error=error,
    )
    return RunResult(
        job_id=result.job_id,
        run_id=result.run_id,
        ok=False,
        exit_code=result.exit_code,
        timed_out=result.timed_out,
        artifacts=(*result.artifacts, summary_ref),
        error=result.error,
    )


def _result_error(*, job_id: str, run_id: str, error_code: str, message: str) -> RunResult:
    return RunResult(
        job_id=job_id,
        run_id=run_id,
        ok=False,
        exit_code=None,
        timed_out=False,
        artifacts=tuple(),
        error=RunError(error_code=error_code, message=message),
    )

