from __future__ import annotations

import logging
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Callable

from src.domain.composition_exec.conditional import ensure_no_depends_on_skipped
from src.domain.composition_exec.dofile import generate_step_do_file_or_error
from src.domain.composition_exec.errors import error_or_default
from src.domain.composition_exec.materialize import materialize_step_inputs
from src.domain.composition_exec.pipeline import fail_pipeline
from src.domain.composition_exec.products import create_products_and_decisions
from src.domain.composition_exec.registry import register_decisions, register_products
from src.domain.composition_exec.run_ids import step_run_id
from src.domain.composition_exec.summary import executed_step_summary, skipped_step_summary
from src.domain.composition_exec.timeout import step_timeout_seconds
from src.domain.composition_exec.types import ExecutionState, MaterializedStepInputs
from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import ArtifactKind, ArtifactRef, Job, LLMPlan, PlanStep
from src.domain.stata_runner import RunError, RunResult, StataRunner
from src.infra.plan_exceptions import PlanCompositionInvalidError
from src.infra.stata_run_support import RunDirs, job_rel_path, resolve_run_dirs
from src.utils.json_types import JsonValue

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class _StepRunSuccess:
    run_id: str
    dirs: RunDirs
    materialized: MaterializedStepInputs
    result: RunResult


@dataclass(frozen=True)
class _StepPhaseContext:
    job: Job
    plan: LLMPlan
    step: PlanStep
    pipeline_dirs: RunDirs
    pipeline_run_id: str
    jobs_dir: Path
    inputs_manifest: Mapping[str, JsonValue]
    composition_mode: str
    manifest_by_key: Mapping[str, str]
    runner: StataRunner
    generator: DoFileGenerator
    shutdown_deadline: datetime | None
    clock: Callable[[], datetime]
    state: ExecutionState


def process_step(
    *,
    job: Job,
    plan: LLMPlan,
    step: PlanStep,
    steps_by_id: Mapping[str, PlanStep],
    pipeline_dirs: RunDirs,
    pipeline_run_id: str,
    jobs_dir: Path,
    inputs_manifest: Mapping[str, JsonValue],
    composition_mode: str,
    manifest_by_key: Mapping[str, str],
    runner: StataRunner,
    generator: DoFileGenerator,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
    state: ExecutionState,
) -> RunResult | None:
    if _maybe_skip_step(state=state, step=step):
        return None
    ensure_no_depends_on_skipped(step=step, skip_reason=state.skip_reason)
    ctx = _StepPhaseContext(
        job=job,
        plan=plan,
        step=step,
        pipeline_dirs=pipeline_dirs,
        pipeline_run_id=pipeline_run_id,
        jobs_dir=jobs_dir,
        inputs_manifest=inputs_manifest,
        composition_mode=composition_mode,
        manifest_by_key=manifest_by_key,
        runner=runner,
        generator=generator,
        shutdown_deadline=shutdown_deadline,
        clock=clock,
        state=state,
    )
    run_phase = _execute_step_run_phase(ctx)
    if isinstance(run_phase, RunResult):
        return run_phase
    return _execute_step_products_phase(
        step=step,
        steps_by_id=steps_by_id,
        pipeline_dirs=pipeline_dirs,
        run_phase=run_phase,
        manifest_by_key=manifest_by_key,
        state=state,
    )


def _execute_step_run_phase(ctx: _StepPhaseContext) -> _StepRunSuccess | RunResult:
    run_id, dirs, materialized = _prepare_step_workspace(ctx=ctx)
    do_file_or_error = generate_step_do_file_or_error(
        generator=ctx.generator,
        plan=ctx.plan,
        step=ctx.step,
        inputs_manifest=materialized.manifest,
    )
    if isinstance(do_file_or_error, RunError):
        return _fail_pipeline(ctx=ctx, error=do_file_or_error)
    result = _run_step(
        job=ctx.job,
        runner=ctx.runner,
        run_id=run_id,
        do_file=do_file_or_error,
        shutdown_deadline=ctx.shutdown_deadline,
        clock=ctx.clock,
        step=ctx.step,
    )
    _record_step_artifacts(
        state=ctx.state,
        pipeline_dirs=ctx.pipeline_dirs,
        result=result,
        inputs_manifest_path=materialized.inputs_dir / "manifest.json",
    )
    if result.ok:
        return _StepRunSuccess(run_id=run_id, dirs=dirs, materialized=materialized, result=result)
    ctx.state.step_summaries.append(
        executed_step_summary(
            step=ctx.step,
            run_id=run_id,
            status="failed",
            bindings=materialized.bindings,
            products=tuple(),
            decisions=tuple(),
        )
    )
    return _fail_pipeline(ctx=ctx, error=error_or_default(result=result))


def _execute_step_products_phase(
    *,
    step: PlanStep,
    steps_by_id: Mapping[str, PlanStep],
    pipeline_dirs: RunDirs,
    run_phase: _StepRunSuccess,
    manifest_by_key: Mapping[str, str],
    state: ExecutionState,
) -> RunResult | None:
    products, decisions = create_products_and_decisions(
        job_dir=pipeline_dirs.job_dir,
        step=step,
        dirs=run_phase.dirs,
        bindings=run_phase.materialized.bindings,
        inputs_by_key=manifest_by_key,
        runner_artifacts=run_phase.result.artifacts,
    )
    register_products(state=state, products=products)
    register_decisions(state=state, step=step, decisions=decisions, steps_by_id=steps_by_id)
    state.step_summaries.append(
        executed_step_summary(
            step=step,
            run_id=run_phase.run_id,
            status="succeeded",
            bindings=run_phase.materialized.bindings,
            products=products,
            decisions=decisions,
        )
    )
    return None


def _maybe_skip_step(*, state: ExecutionState, step: PlanStep) -> bool:
    reason = state.skip_reason.get(step.step_id)
    if reason is None:
        return False
    state.step_summaries.append(skipped_step_summary(step=step, reason=reason))
    return True


def _prepare_step_workspace(
    *,
    ctx: _StepPhaseContext,
) -> tuple[str, RunDirs, MaterializedStepInputs]:
    run_id = step_run_id(pipeline_run_id=ctx.pipeline_run_id, step_id=ctx.step.step_id)
    dirs = resolve_run_dirs(
        jobs_dir=ctx.jobs_dir,
        tenant_id=ctx.job.tenant_id,
        job_id=ctx.job.job_id,
        run_id=run_id,
    )
    if dirs is None:
        raise PlanCompositionInvalidError(reason="step_run_dirs_invalid", step_id=ctx.step.step_id)
    materialized = materialize_step_inputs(
        job_dir=ctx.pipeline_dirs.job_dir,
        step=ctx.step,
        dirs=dirs,
        inputs_by_key=ctx.manifest_by_key,
        products=ctx.state.products,
    )
    return run_id, dirs, materialized


def _run_step(
    *,
    job: Job,
    runner: StataRunner,
    run_id: str,
    do_file: str,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
    step: PlanStep,
) -> RunResult:
    timeout_seconds = step_timeout_seconds(
        step=step,
        shutdown_deadline=shutdown_deadline,
        clock=clock,
    )
    return runner.run(
        tenant_id=job.tenant_id,
        job_id=job.job_id,
        run_id=run_id,
        do_file=do_file,
        timeout_seconds=timeout_seconds,
        inputs_dir_rel=f"runs/{run_id}/inputs",
    )


def _record_step_artifacts(
    *,
    state: ExecutionState,
    pipeline_dirs: RunDirs,
    result: RunResult,
    inputs_manifest_path: Path,
) -> None:
    state.artifacts.extend(result.artifacts)
    state.artifacts.append(
        ArtifactRef(
            kind=ArtifactKind.INPUTS_MANIFEST,
            rel_path=job_rel_path(job_dir=pipeline_dirs.job_dir, path=inputs_manifest_path),
        )
    )


def _fail_pipeline(*, ctx: _StepPhaseContext, error: RunError) -> RunResult:
    return fail_pipeline(
        job=ctx.job,
        pipeline_dirs=ctx.pipeline_dirs,
        pipeline_run_id=ctx.pipeline_run_id,
        inputs_manifest=ctx.inputs_manifest,
        composition_mode=ctx.composition_mode,
        steps=ctx.state.step_summaries,
        decisions=ctx.state.decisions,
        error=error,
    )
