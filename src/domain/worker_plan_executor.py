from __future__ import annotations

import logging
from datetime import datetime
from typing import Callable

from src.domain.models import Job, PlanStep, PlanStepType
from src.domain.stata_runner import RunError, RunResult, StataRunner

logger = logging.getLogger(__name__)


def execute_plan(
    *,
    job: Job,
    run_id: str,
    runner: StataRunner,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
) -> RunResult:
    if job.llm_plan is None:
        logger.warning("SS_WORKER_PLAN_MISSING", extra={"job_id": job.job_id})
        return RunResult(
            job_id=job.job_id,
            run_id=run_id,
            ok=False,
            exit_code=None,
            timed_out=False,
            artifacts=tuple(),
            error=RunError(error_code="PLAN_MISSING", message="job missing llm_plan"),
        )

    do_file = ""
    for step in job.llm_plan.steps:
        if step.type == PlanStepType.GENERATE_STATA_DO:
            do_file = _generate_do_file(job=job, run_id=run_id, step=step)
            continue
        if step.type == PlanStepType.RUN_STATA:
            timeout_seconds = _timeout_seconds(step=step)
            effective_timeout_seconds = _cap_timeout_seconds(
                timeout_seconds=timeout_seconds,
                shutdown_deadline=shutdown_deadline,
                clock=clock,
            )
            if do_file == "":
                do_file = _default_do_file(job=job, run_id=run_id)
            return runner.run(
                job_id=job.job_id,
                run_id=run_id,
                do_file=do_file,
                timeout_seconds=effective_timeout_seconds,
            )

    logger.warning("SS_WORKER_PLAN_NO_RUN_STEP", extra={"job_id": job.job_id})
    return RunResult(
        job_id=job.job_id,
        run_id=run_id,
        ok=False,
        exit_code=None,
        timed_out=False,
        artifacts=tuple(),
        error=RunError(error_code="PLAN_INVALID", message="plan missing RUN_STATA step"),
    )


def _generate_do_file(*, job: Job, run_id: str, step: PlanStep) -> str:
    template = str(step.params.get("template", ""))
    requirement_fingerprint = str(step.params.get("requirement_fingerprint", ""))
    lines = [
        "* SS generated do-file (stub)",
        f"* template: {template}",
        f"* job_id: {job.job_id}",
        f"* run_id: {run_id}",
        f"* requirement_fingerprint: {requirement_fingerprint}",
        'display "SS stub do-file"',
        "exit 0",
    ]
    return "\n".join(lines) + "\n"


def _default_do_file(*, job: Job, run_id: str) -> str:
    lines = [
        "* SS generated do-file (default)",
        f"* job_id: {job.job_id}",
        f"* run_id: {run_id}",
        'display "SS default do-file"',
        "exit 0",
    ]
    return "\n".join(lines) + "\n"


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
