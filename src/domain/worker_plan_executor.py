from __future__ import annotations

import logging
from datetime import datetime
from pathlib import Path
from typing import Callable

from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import Job
from src.domain.stata_dependency_checker import StataDependencyChecker
from src.domain.stata_runner import RunError, RunResult, StataRunner
from src.domain.worker_plan_execution import execute_in_dirs
from src.domain.worker_plan_executor_support import (
    declared_stata_dependencies,
    dependency_error_details,
)
from src.domain.worker_plan_support import write_pre_run_error
from src.infra.stata_run_support import resolve_run_dirs

logger = logging.getLogger(__name__)


def execute_plan(
    *,
    job: Job,
    run_id: str,
    jobs_dir: Path,
    runner: StataRunner,
    dependency_checker: StataDependencyChecker | None = None,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
    do_file_generator: DoFileGenerator | None = None,
) -> RunResult:
    dirs = resolve_run_dirs(
        jobs_dir=Path(jobs_dir),
        tenant_id=job.tenant_id,
        job_id=job.job_id,
        run_id=run_id,
    )
    if dirs is None:
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
            error=RunError(
                error_code="STATA_WORKSPACE_INVALID",
                message="invalid job/run workspace",
            ),
        )

    dependency_error = _dependency_preflight_or_none(
        job=job,
        run_id=run_id,
        dependency_checker=dependency_checker,
    )
    if dependency_error is not None:
        return write_pre_run_error(
            dirs=dirs,
            job_id=job.job_id,
            run_id=run_id,
            error=dependency_error,
        )

    return execute_in_dirs(
        job=job,
        run_id=run_id,
        dirs=dirs,
        jobs_dir=Path(jobs_dir),
        runner=runner,
        shutdown_deadline=shutdown_deadline,
        clock=clock,
        do_file_generator=do_file_generator,
    )


def _dependency_preflight_or_none(
    *,
    job: Job,
    run_id: str,
    dependency_checker: StataDependencyChecker | None,
) -> RunError | None:
    if dependency_checker is None:
        return None
    if job.llm_plan is None:
        return None

    declared = declared_stata_dependencies(plan=job.llm_plan)
    if not declared:
        return None

    checked = dependency_checker.check(
        tenant_id=job.tenant_id,
        job_id=job.job_id,
        run_id=run_id,
        dependencies=declared,
    )
    if checked.error is not None:
        logger.warning(
            "SS_WORKER_DEPENDENCY_PREFLIGHT_FAILED",
            extra={"job_id": job.job_id, "run_id": run_id, "error_code": checked.error.error_code},
        )
        return checked.error
    if checked.missing:
        missing = [dep.pkg for dep in checked.missing]
        logger.warning(
            "SS_WORKER_DEPENDENCY_MISSING",
            extra={"job_id": job.job_id, "run_id": run_id, "missing": missing},
        )
        return RunError(
            error_code="STATA_DEPENDENCY_MISSING",
            message=f"missing Stata dependencies: {', '.join(missing)}",
            details=dependency_error_details(missing=checked.missing),
        )
    return None
