from __future__ import annotations

import json
import logging
from collections.abc import Mapping

from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import ArtifactKind, ArtifactRef, Job, LLMPlan
from src.domain.plan_routing import extract_input_dataset_keys
from src.infra.exceptions import JobStoreIOError
from src.infra.input_exceptions import InputPathUnsafeError
from src.infra.plan_exceptions import PlanArtifactsWriteError

logger = logging.getLogger(__name__)

RUN_STATA_PRODUCES = [
    ArtifactKind.RUN_STDOUT,
    ArtifactKind.RUN_STDERR,
    ArtifactKind.STATA_LOG,
    ArtifactKind.STATA_EXPORT_TABLE,
    ArtifactKind.RUN_META_JSON,
    ArtifactKind.RUN_ERROR_JSON,
]


def known_input_keys(*, workspace: JobWorkspaceStore, job: Job) -> set[str]:
    default = {"primary"}
    inputs = job.inputs
    rel_path = None if inputs is None else inputs.manifest_rel_path
    if rel_path is None or rel_path.strip() == "":
        return default
    try:
        path = workspace.resolve_for_read(
            tenant_id=job.tenant_id,
            job_id=job.job_id,
            rel_path=rel_path,
        )
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError, InputPathUnsafeError) as e:
        logger.warning(
            "SS_PLAN_INPUTS_MANIFEST_READ_FAILED",
            extra={
                "tenant_id": job.tenant_id,
                "job_id": job.job_id,
                "rel_path": rel_path,
                "reason": str(e),
            },
        )
        return default
    if not isinstance(raw, Mapping):
        logger.warning(
            "SS_PLAN_INPUTS_MANIFEST_INVALID",
            extra={"tenant_id": job.tenant_id, "job_id": job.job_id, "rel_path": rel_path},
        )
        return default
    keys = extract_input_dataset_keys(manifest=raw)
    return default if len(keys) == 0 else keys


def write_plan_artifact(*, store: JobStore, tenant_id: str, job_id: str, plan: LLMPlan) -> None:
    try:
        store.write_artifact_json(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=plan.rel_path,
            payload=plan.model_dump(mode="json"),
        )
    except JobStoreIOError as e:
        logger.warning(
            "SS_PLAN_ARTIFACT_WRITE_FAILED",
            extra={"job_id": job_id, "error_code": e.error_code, "error_message": e.message},
        )
        raise PlanArtifactsWriteError(job_id=job_id) from e


def ensure_plan_artifact_index(*, job: Job, rel_path: str) -> None:
    for ref in job.artifacts_index:
        if ref.kind == ArtifactKind.PLAN_JSON and ref.rel_path == rel_path:
            return
    job.artifacts_index.append(ArtifactRef(kind=ArtifactKind.PLAN_JSON, rel_path=rel_path))
