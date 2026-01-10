from __future__ import annotations

import logging
from collections.abc import Mapping
from pathlib import Path
from typing import cast

from src.domain.do_file_generator import DoFileGenerator, GeneratedDoFile, PreparedDoTemplate
from src.domain.do_template_run_evidence import (
    archive_outputs,
    write_run_meta,
    write_template_evidence,
)
from src.domain.models import ArtifactRef, Job
from src.domain.stata_runner import RunError
from src.infra.exceptions import (
    DoFileInputsManifestInvalidError as InputsManifestInvalid,
)
from src.infra.exceptions import (
    DoFilePlanInvalidError as PlanInvalid,
)
from src.infra.exceptions import (
    DoFileTemplateUnsupportedError as TemplateUnsupported,
)
from src.infra.exceptions import (
    DoTemplateArtifactsWriteError,
    DoTemplateContractInvalidError,
    DoTemplateParameterInvalidError,
    DoTemplateParameterMissingError,
)
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


def prepare_template_or_error(
    *,
    generator: DoFileGenerator,
    job: Job,
    run_id: str,
    inputs_manifest: Mapping[str, object],
) -> PreparedDoTemplate | RunError:
    if job.llm_plan is None:
        return RunError(error_code="PLAN_MISSING", message="job missing llm_plan")
    try:
        return generator.prepare(plan=job.llm_plan, inputs_manifest=inputs_manifest)
    except (PlanInvalid, TemplateUnsupported, InputsManifestInvalid) as e:
        logger.warning(
            "SS_WORKER_DOFILE_PREPARE_FAILED",
            extra={
                "job_id": job.job_id,
                "run_id": run_id,
                "plan_id": job.llm_plan.plan_id,
                "error_code": e.error_code,
            },
        )
        return RunError(error_code=e.error_code, message=e.message)


def generate_do_file_or_error(
    *,
    generator: DoFileGenerator,
    job: Job,
    run_id: str,
    prepared: PreparedDoTemplate,
) -> GeneratedDoFile | RunError:
    try:
        return generator.generate_from_prepared(prepared=prepared)
    except (
        DoTemplateParameterMissingError,
        DoTemplateParameterInvalidError,
        DoTemplateContractInvalidError,
    ) as e:
        logger.warning(
            "SS_WORKER_DOFILE_GENERATION_FAILED",
            extra={"job_id": job.job_id, "run_id": run_id, "error_code": e.error_code},
        )
        return RunError(error_code=e.error_code, message=e.message)


def write_template_evidence_or_error(
    *,
    job: Job,
    run_id: str,
    template_id: str,
    raw_do: str,
    meta: object,
    params: dict[str, str],
    artifacts_dir: Path,
    job_dir: Path,
) -> tuple[ArtifactRef, ...] | RunError:
    if not isinstance(meta, dict):
        return RunError(
            error_code="DO_TEMPLATE_META_INVALID",
            message="do template meta must be a JSON object",
        )
    try:
        return write_template_evidence(
            job_id=job.job_id,
            run_id=run_id,
            template_id=template_id,
            raw_do=raw_do,
            meta=cast(JsonObject, meta),
            params=params,
            artifacts_dir=artifacts_dir,
            job_dir=job_dir,
        )
    except DoTemplateArtifactsWriteError as e:
        return RunError(error_code=e.error_code, message=e.message)


def archive_outputs_or_error(
    *,
    job: Job,
    template_id: str,
    meta: object,
    work_dir: Path,
    artifacts_dir: Path,
    job_dir: Path,
) -> tuple[tuple[ArtifactRef, ...], tuple[str, ...]] | RunError:
    if not isinstance(meta, dict):
        return RunError(
            error_code="DO_TEMPLATE_META_INVALID",
            message="do template meta must be a JSON object",
        )
    try:
        return archive_outputs(
            template_id=template_id,
            meta=cast(JsonObject, meta),
            work_dir=work_dir,
            artifacts_dir=artifacts_dir,
            job_dir=job_dir,
        )
    except (DoTemplateContractInvalidError, DoTemplateArtifactsWriteError, OSError) as e:
        logger.warning(
            "SS_WORKER_OUTPUT_ARCHIVE_FAILED",
            extra={"job_id": job.job_id, "template_id": template_id, "reason": str(e)},
        )
        return RunError(
            error_code="DO_TEMPLATE_OUTPUT_ARCHIVE_FAILED",
            message=f"failed to archive declared outputs: {template_id}",
        )


def write_do_template_run_meta_or_error(
    *,
    job: Job,
    run_id: str,
    template_id: str,
    params: dict[str, str],
    archived_outputs: tuple[ArtifactRef, ...],
    missing_outputs: tuple[str, ...],
    artifacts_dir: Path,
    job_dir: Path,
) -> ArtifactRef | RunError:
    try:
        return write_run_meta(
            job_id=job.job_id,
            run_id=run_id,
            template_id=template_id,
            params=params,
            archived_outputs=archived_outputs,
            missing_outputs=missing_outputs,
            artifacts_dir=artifacts_dir,
            job_dir=job_dir,
        )
    except DoTemplateArtifactsWriteError as e:
        return RunError(error_code=e.error_code, message=e.message)
