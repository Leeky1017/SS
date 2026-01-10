from __future__ import annotations

import json
import logging
from collections.abc import Mapping
from datetime import datetime
from pathlib import Path
from typing import Callable, cast

from src.domain.composition_executor import execute_composition_plan as execute_composition_plan
from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import Job, PlanStep, PlanStepType
from src.domain.stata_dependency_checker import StataDependencyChecker
from src.domain.stata_runner import RunError, RunResult, StataRunner
from src.domain.worker_plan_executor_support import (
    cap_timeout_seconds,
    declared_stata_dependencies,
    dependency_error_details,
    timeout_seconds_from_step,
)
from src.domain.worker_pre_run_error import write_pre_run_error
from src.infra.exceptions import DoFileInputsManifestInvalidError as InputsManifestInvalid
from src.infra.exceptions import DoFilePlanInvalidError as PlanInvalid
from src.infra.exceptions import DoFileTemplateUnsupportedError as TemplateUnsupported
from src.infra.stata_run_support import (
    RunDirs,
    resolve_run_dirs,
)
from src.utils.json_types import JsonValue

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
    dirs_or_error = _resolve_run_dirs_or_error(jobs_dir=jobs_dir, job=job, run_id=run_id)
    if isinstance(dirs_or_error, RunResult):
        return dirs_or_error
    dirs = dirs_or_error

    if job.llm_plan is None:
        logger.warning("SS_WORKER_PLAN_MISSING", extra={"job_id": job.job_id, "run_id": run_id})
        return write_pre_run_error(
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
        return write_pre_run_error(
            dirs=dirs,
            job_id=job.job_id,
            run_id=run_id,
            error=inputs_manifest,
        )

    if dependency_checker is not None and job.llm_plan is not None:
        declared = declared_stata_dependencies(plan=job.llm_plan)
        if declared:
            checked = dependency_checker.check(
                tenant_id=job.tenant_id,
                job_id=job.job_id,
                run_id=run_id,
                dependencies=declared,
            )
            if checked.error is not None:
                logger.warning(
                    "SS_WORKER_DEPENDENCY_PREFLIGHT_FAILED",
                    extra={
                        "job_id": job.job_id,
                        "run_id": run_id,
                        "error_code": checked.error.error_code,
                    },
                )
                return write_pre_run_error(
                    dirs=dirs,
                    job_id=job.job_id,
                    run_id=run_id,
                    error=checked.error,
                )
            if checked.missing:
                missing = [dep.pkg for dep in checked.missing]
                logger.warning(
                    "SS_WORKER_DEPENDENCY_MISSING",
                    extra={"job_id": job.job_id, "run_id": run_id, "missing": missing},
                )
                return write_pre_run_error(
                    dirs=dirs,
                    job_id=job.job_id,
                    run_id=run_id,
                    error=RunError(
                        error_code="STATA_DEPENDENCY_MISSING",
                        message=f"missing Stata dependencies: {', '.join(missing)}",
                        details=dependency_error_details(missing=checked.missing),
                    ),
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
        return write_pre_run_error(dirs=dirs, job_id=job.job_id, run_id=run_id, error=do_file)

    timeout_seconds = timeout_seconds_from_step(step=run_step)
    effective_timeout_seconds = cap_timeout_seconds(
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
