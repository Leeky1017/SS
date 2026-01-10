from __future__ import annotations

import logging
from collections.abc import Mapping
from datetime import datetime
from pathlib import Path
from typing import Callable, cast

from src.domain.composition_executor import execute_composition_plan
from src.domain.do_file_generator import DoFileGenerator, GeneratedDoFile, PreparedDoTemplate
from src.domain.models import ArtifactRef, Job, PlanStep
from src.domain.stata_runner import RunError, RunResult, StataRunner
from src.domain.worker_do_template_artifacts import (
    archive_outputs_or_error,
    generate_do_file_or_error,
    prepare_template_or_error,
    write_do_template_run_meta_or_error,
    write_template_evidence_or_error,
)
from src.domain.worker_plan_support import (
    effective_timeout_seconds,
    failed_runner_result,
    find_run_step,
    inputs_manifest_or_error,
    write_pre_run_error,
)
from src.infra.stata_run_support import RunDirs
from src.utils.json_types import JsonValue

logger = logging.getLogger(__name__)


def execute_in_dirs(
    *,
    job: Job,
    run_id: str,
    dirs: RunDirs,
    jobs_dir: Path,
    runner: StataRunner,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
    do_file_generator: DoFileGenerator | None,
) -> RunResult:
    if job.llm_plan is None:
        return write_pre_run_error(
            dirs=dirs,
            job_id=job.job_id,
            run_id=run_id,
            error=RunError(error_code="PLAN_MISSING", message="job missing llm_plan"),
        )

    inputs_manifest = inputs_manifest_or_error(job=job, job_dir=dirs.job_dir)
    if isinstance(inputs_manifest, RunError):
        return write_pre_run_error(
            dirs=dirs,
            job_id=job.job_id,
            run_id=run_id,
            error=inputs_manifest,
        )

    return _execute_with_inputs(
        job=job,
        run_id=run_id,
        dirs=dirs,
        jobs_dir=jobs_dir,
        runner=runner,
        shutdown_deadline=shutdown_deadline,
        clock=clock,
        do_file_generator=do_file_generator,
        inputs_manifest=inputs_manifest,
    )


def _execute_with_inputs(
    *,
    job: Job,
    run_id: str,
    dirs: RunDirs,
    jobs_dir: Path,
    runner: StataRunner,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
    do_file_generator: DoFileGenerator | None,
    inputs_manifest: dict[str, JsonValue],
) -> RunResult:
    plan = job.llm_plan
    if plan is None:
        return write_pre_run_error(
            dirs=dirs,
            job_id=job.job_id,
            run_id=run_id,
            error=RunError(error_code="PLAN_MISSING", message="job missing llm_plan"),
        )
    generator = DoFileGenerator() if do_file_generator is None else do_file_generator
    run_step = find_run_step(steps=plan.steps)
    if run_step is None:
        return execute_composition_plan(
            job=job,
            run_id=run_id,
            jobs_dir=jobs_dir,
            runner=runner,
            inputs_manifest=inputs_manifest,
            shutdown_deadline=shutdown_deadline,
            clock=clock,
            do_file_generator=generator,
        )

    return _execute_run_step(
        job=job,
        run_id=run_id,
        dirs=dirs,
        runner=runner,
        generator=generator,
        shutdown_deadline=shutdown_deadline,
        clock=clock,
        run_step=run_step,
        inputs_manifest=cast(Mapping[str, object], inputs_manifest),
    )


def _execute_run_step(
    *,
    job: Job,
    run_id: str,
    dirs: RunDirs,
    runner: StataRunner,
    generator: DoFileGenerator,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
    run_step: PlanStep,
    inputs_manifest: Mapping[str, object],
) -> RunResult:
    dirs.work_dir.mkdir(parents=True, exist_ok=True)
    dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)

    generated_or_error = _generate_with_template_evidence(
        job=job,
        run_id=run_id,
        dirs=dirs,
        generator=generator,
        inputs_manifest=inputs_manifest,
    )
    if isinstance(generated_or_error, RunResult):
        return generated_or_error
    generated, template_refs = generated_or_error

    effective_timeout = effective_timeout_seconds(
        step=run_step,
        shutdown_deadline=shutdown_deadline,
        clock=clock,
    )
    runner_result = runner.run(
        tenant_id=job.tenant_id,
        job_id=job.job_id,
        run_id=run_id,
        do_file=generated.do_file,
        timeout_seconds=effective_timeout,
    )
    return _finalize_template_run(
        job=job,
        run_id=run_id,
        dirs=dirs,
        generated=generated,
        template_refs=template_refs,
        runner_result=runner_result,
    )


def _generate_with_template_evidence(
    *,
    job: Job,
    run_id: str,
    dirs: RunDirs,
    generator: DoFileGenerator,
    inputs_manifest: Mapping[str, object],
) -> tuple[GeneratedDoFile, tuple[ArtifactRef, ...]] | RunResult:
    prepared = prepare_template_or_error(
        generator=generator,
        job=job,
        run_id=run_id,
        inputs_manifest=inputs_manifest,
    )
    if isinstance(prepared, RunError):
        return write_pre_run_error(dirs=dirs, job_id=job.job_id, run_id=run_id, error=prepared)

    generated = generate_do_file_or_error(
        generator=generator,
        job=job,
        run_id=run_id,
        prepared=prepared,
    )
    if isinstance(generated, RunError):
        return _generation_failed(
            job=job,
            run_id=run_id,
            dirs=dirs,
            prepared=prepared,
            generation_error=generated,
        )

    template_refs = _write_template_evidence_for_generated(
        job=job,
        run_id=run_id,
        dirs=dirs,
        generated=generated,
    )
    if isinstance(template_refs, RunError):
        return write_pre_run_error(dirs=dirs, job_id=job.job_id, run_id=run_id, error=template_refs)
    return generated, template_refs


def _generation_failed(
    *,
    job: Job,
    run_id: str,
    dirs: RunDirs,
    prepared: PreparedDoTemplate,
    generation_error: RunError,
) -> RunResult:
    template_refs = write_template_evidence_or_error(
        job=job,
        run_id=run_id,
        template_id=prepared.template_id,
        raw_do=prepared.raw_do,
        meta=prepared.meta,
        params=prepared.params,
        artifacts_dir=dirs.artifacts_dir,
        job_dir=dirs.job_dir,
    )
    if isinstance(template_refs, RunError):
        return write_pre_run_error(dirs=dirs, job_id=job.job_id, run_id=run_id, error=template_refs)
    return write_pre_run_error(
        dirs=dirs,
        job_id=job.job_id,
        run_id=run_id,
        error=generation_error,
        extra_artifacts=template_refs,
    )


def _write_template_evidence_for_generated(
    *,
    job: Job,
    run_id: str,
    dirs: RunDirs,
    generated: GeneratedDoFile,
) -> tuple[ArtifactRef, ...] | RunError:
    return write_template_evidence_or_error(
        job=job,
        run_id=run_id,
        template_id=generated.template_id,
        raw_do=generated.template_source,
        meta=generated.template_meta,
        params=generated.template_params,
        artifacts_dir=dirs.artifacts_dir,
        job_dir=dirs.job_dir,
    )


def _finalize_template_run(
    *,
    job: Job,
    run_id: str,
    dirs: RunDirs,
    generated: GeneratedDoFile,
    template_refs: tuple[ArtifactRef, ...],
    runner_result: RunResult,
) -> RunResult:
    outputs = archive_outputs_or_error(
        job=job,
        template_id=generated.template_id,
        meta=generated.template_meta,
        work_dir=dirs.work_dir,
        artifacts_dir=dirs.artifacts_dir,
        job_dir=dirs.job_dir,
    )
    if isinstance(outputs, RunError):
        return failed_runner_result(
            runner_result=runner_result,
            error=outputs,
            artifacts=(*template_refs, *runner_result.artifacts),
        )
    output_refs, missing = outputs
    run_meta = write_do_template_run_meta_or_error(
        job=job,
        run_id=run_id,
        template_id=generated.template_id,
        params=generated.template_params,
        archived_outputs=output_refs,
        missing_outputs=missing,
        artifacts_dir=dirs.artifacts_dir,
        job_dir=dirs.job_dir,
    )
    if isinstance(run_meta, RunError):
        return failed_runner_result(
            runner_result=runner_result,
            error=run_meta,
            artifacts=(*template_refs, *output_refs, *runner_result.artifacts),
        )
    return RunResult(
        job_id=runner_result.job_id,
        run_id=runner_result.run_id,
        ok=runner_result.ok,
        exit_code=runner_result.exit_code,
        timed_out=runner_result.timed_out,
        artifacts=(*template_refs, run_meta, *output_refs, *runner_result.artifacts),
        error=runner_result.error,
    )
