from __future__ import annotations

import logging
from collections.abc import Mapping
from datetime import datetime
from pathlib import Path
from typing import Callable

from src.domain.composition_exec.ordering import validate_step_ids
from src.domain.composition_exec.pipeline import fail_pipeline, pipeline_dirs_or_error
from src.domain.composition_exec.plan_execution import execute_steps, validate_mode
from src.domain.composition_exec.summary import write_pipeline_summary
from src.domain.composition_exec.types import ExecutionState
from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import Job, LLMPlan
from src.domain.stata_runner import RunError, RunResult, StataRunner
from src.infra.plan_exceptions import PlanCompositionInvalidError
from src.infra.stata_run_support import RunDirs
from src.utils.json_types import JsonValue

logger = logging.getLogger(__name__)


def execute_composition_plan(
    *,
    job: Job,
    run_id: str,
    jobs_dir: Path,
    runner: StataRunner,
    inputs_manifest: Mapping[str, JsonValue],
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
    do_file_generator: DoFileGenerator | None = None,
) -> RunResult:
    plan = job.llm_plan
    if plan is None:
        return _plan_missing_result(job_id=job.job_id, run_id=run_id)

    pipeline_dirs = pipeline_dirs_or_error(job=job, run_id=run_id, jobs_dir=jobs_dir)
    if isinstance(pipeline_dirs, RunResult):
        return pipeline_dirs

    generator = DoFileGenerator() if do_file_generator is None else do_file_generator
    return _execute_composition_plan_validated(
        job=job,
        plan=plan,
        pipeline_dirs=pipeline_dirs,
        pipeline_run_id=run_id,
        jobs_dir=Path(jobs_dir),
        runner=runner,
        inputs_manifest=inputs_manifest,
        generator=generator,
        shutdown_deadline=shutdown_deadline,
        clock=clock,
    )


def _execute_composition_plan_validated(
    *,
    job: Job,
    plan: LLMPlan,
    pipeline_dirs: RunDirs,
    pipeline_run_id: str,
    jobs_dir: Path,
    runner: StataRunner,
    inputs_manifest: Mapping[str, JsonValue],
    generator: DoFileGenerator,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
) -> RunResult:
    try:
        validate_step_ids(plan=plan)
        mode = validate_mode(plan=plan, inputs_manifest=inputs_manifest)
        state = execute_steps(
            job=job,
            plan=plan,
            pipeline_dirs=pipeline_dirs,
            pipeline_run_id=pipeline_run_id,
            jobs_dir=jobs_dir,
            inputs_manifest=inputs_manifest,
            composition_mode=mode.value,
            runner=runner,
            generator=generator,
            shutdown_deadline=shutdown_deadline,
            clock=clock,
        )
        return _finalize_pipeline(
            job=job,
            pipeline_dirs=pipeline_dirs,
            pipeline_run_id=pipeline_run_id,
            inputs_manifest=inputs_manifest,
            composition_mode=mode.value,
            state_or_result=state,
        )
    except PlanCompositionInvalidError as e:
        return _handle_plan_invalid(
            job=job,
            pipeline_dirs=pipeline_dirs,
            pipeline_run_id=pipeline_run_id,
            inputs_manifest=inputs_manifest,
            error=e,
        )


def _handle_plan_invalid(
    *,
    job: Job,
    pipeline_dirs: RunDirs,
    pipeline_run_id: str,
    inputs_manifest: Mapping[str, JsonValue],
    error: PlanCompositionInvalidError,
) -> RunResult:
    logger.warning(
        "SS_COMPOSITION_PLAN_INVALID",
        extra={"job_id": job.job_id, "run_id": pipeline_run_id, "reason": error.message},
    )
    return fail_pipeline(
        job=job,
        pipeline_dirs=pipeline_dirs,
        pipeline_run_id=pipeline_run_id,
        inputs_manifest=inputs_manifest,
        composition_mode="unknown",
        steps=[],
        decisions=[],
        error=RunError(error_code=error.error_code, message=error.message),
    )


def _finalize_pipeline(
    *,
    job: Job,
    pipeline_dirs: RunDirs,
    pipeline_run_id: str,
    inputs_manifest: Mapping[str, JsonValue],
    composition_mode: str,
    state_or_result: ExecutionState | RunResult,
) -> RunResult:
    if isinstance(state_or_result, RunResult):
        return state_or_result
    state = state_or_result
    state.artifacts.append(
        write_pipeline_summary(
            job=job,
            job_dir=pipeline_dirs.job_dir,
            pipeline_run_id=pipeline_run_id,
            artifacts_dir=pipeline_dirs.artifacts_dir,
            composition_mode=composition_mode,
            inputs_manifest=inputs_manifest,
            steps=state.step_summaries,
            decisions=state.decisions,
        )
    )
    return RunResult(
        job_id=job.job_id,
        run_id=pipeline_run_id,
        ok=True,
        exit_code=None,
        timed_out=False,
        artifacts=tuple(state.artifacts),
    )


def _plan_missing_result(*, job_id: str, run_id: str) -> RunResult:
    return RunResult(
        job_id=job_id,
        run_id=run_id,
        ok=False,
        exit_code=None,
        timed_out=False,
        artifacts=tuple(),
        error=RunError(error_code="PLAN_MISSING", message="plan missing"),
    )
