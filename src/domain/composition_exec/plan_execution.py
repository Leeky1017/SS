from __future__ import annotations

from collections.abc import Mapping
from datetime import datetime
from pathlib import Path
from typing import Callable

from src.domain.composition_exec.ordering import toposort
from src.domain.composition_exec.refs import inputs_by_key
from src.domain.composition_exec.step_execution import process_step
from src.domain.composition_exec.types import ExecutionState
from src.domain.composition_plan import CompositionMode, validate_composition_plan
from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import Job, LLMPlan
from src.domain.plan_routing import extract_input_dataset_keys
from src.domain.stata_runner import RunResult, StataRunner
from src.infra.stata_run_support import RunDirs
from src.utils.json_types import JsonValue


def validate_mode(*, plan: LLMPlan, inputs_manifest: Mapping[str, JsonValue]) -> CompositionMode:
    known = extract_input_dataset_keys(manifest=inputs_manifest)
    return validate_composition_plan(plan=plan, known_input_keys=known)


def execute_steps(
    *,
    job: Job,
    plan: LLMPlan,
    pipeline_dirs: RunDirs,
    pipeline_run_id: str,
    jobs_dir: Path,
    inputs_manifest: Mapping[str, JsonValue],
    composition_mode: str,
    runner: StataRunner,
    generator: DoFileGenerator,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
) -> ExecutionState | RunResult:
    steps_by_id = {step.step_id: step for step in plan.steps}
    order = toposort(plan=plan)
    manifest_by_key = inputs_by_key(inputs_manifest=inputs_manifest)
    state = ExecutionState(
        products={},
        step_summaries=[],
        skip_reason={},
        decisions=[],
        artifacts=[],
    )
    for step_id in order:
        result = process_step(
            job=job,
            plan=plan,
            step=steps_by_id[step_id],
            steps_by_id=steps_by_id,
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
        if result is not None:
            return result
    return state
