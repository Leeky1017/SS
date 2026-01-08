from __future__ import annotations

import logging
from collections.abc import Mapping
from pathlib import Path

from src.domain.composition_exec.types import ResolvedBinding, ResolvedProduct
from src.domain.models import ArtifactKind, ArtifactRef, Job, PlanStep
from src.domain.stata_runner import RunError, RunResult
from src.infra.stata_run_support import RunDirs, job_rel_path, write_json
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


def executed_step_summary(
    *,
    step: PlanStep,
    run_id: str,
    status: str,
    bindings: tuple[ResolvedBinding, ...],
    products: tuple[ResolvedProduct, ...],
    decisions: tuple[JsonObject, ...],
) -> JsonObject:
    return {
        "step_id": step.step_id,
        "run_id": run_id,
        "status": status,
        "template_id": step.params.get("template_id", ""),
        "depends_on": list(step.depends_on),
        "bindings": [
            {
                "role": b.role,
                "dataset_ref": b.dataset_ref,
                "source_rel_path": b.source_rel_path,
                "dest_filename": b.dest_filename,
            }
            for b in bindings
        ],
        "products": [
            {
                "product_id": p.product_id,
                "kind": p.kind.value,
                "artifact_rel_path": p.artifact_rel_path,
            }
            for p in products
        ],
        "decisions": [dict(d) for d in decisions],
        "evidence_dir_rel": f"runs/{run_id}",
    }


def skipped_step_summary(*, step: PlanStep, reason: str) -> JsonObject:
    return {
        "step_id": step.step_id,
        "run_id": None,
        "status": "skipped",
        "reason": reason,
        "depends_on": list(step.depends_on),
    }


def write_pipeline_summary(
    *,
    job: Job,
    job_dir: Path,
    pipeline_run_id: str,
    artifacts_dir: Path,
    composition_mode: str,
    inputs_manifest: Mapping[str, object],
    steps: list[JsonObject],
    decisions: list[JsonObject],
    error: Mapping[str, object] | None = None,
) -> ArtifactRef:
    path = artifacts_dir / "composition_summary.json"
    payload: JsonObject = {
        "schema_version": 1,
        "job_id": job.job_id,
        "pipeline_run_id": pipeline_run_id,
        "composition_mode": composition_mode,
        "inputs_manifest": dict(inputs_manifest),
        "steps": steps,
        "decisions": decisions,
    }
    if error is not None:
        payload["error"] = dict(error)
    write_json(path, payload)
    return ArtifactRef(
        kind=ArtifactKind.COMPOSITION_SUMMARY_JSON,
        rel_path=job_rel_path(job_dir=job_dir, path=path),
    )


def write_pipeline_error(
    *,
    pipeline_dirs: RunDirs,
    job_id: str,
    run_id: str,
    error: RunError,
) -> RunResult:
    payload: JsonObject = {
        "error_code": error.error_code,
        "message": error.message,
        "timed_out": False,
        "exit_code": None,
    }
    path = pipeline_dirs.artifacts_dir / "run.error.json"
    try:
        write_json(path, payload)
    except OSError as e:
        logger.warning(
            "SS_COMPOSITION_PIPELINE_ERROR_WRITE_FAILED",
            extra={"job_id": job_id, "run_id": run_id, "reason": str(e)},
        )
        error = RunError(error_code="COMPOSITION_PIPELINE_ERROR_WRITE_FAILED", message=str(e))
        return RunResult(
            job_id=job_id,
            run_id=run_id,
            ok=False,
            exit_code=None,
            timed_out=False,
            artifacts=tuple(),
            error=error,
        )
    return RunResult(
        job_id=job_id,
        run_id=run_id,
        ok=False,
        exit_code=None,
        timed_out=False,
        artifacts=(
            ArtifactRef(
                kind=ArtifactKind.RUN_ERROR_JSON,
                rel_path=job_rel_path(job_dir=pipeline_dirs.job_dir, path=path),
            ),
        ),
        error=error,
    )
