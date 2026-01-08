from __future__ import annotations

import logging
import shutil
from pathlib import Path, PurePosixPath

from src.domain.models import ArtifactKind, ArtifactRef, Job, JobStatus
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import DoTemplateArtifactsWriteError, DoTemplateContractInvalidError
from src.infra.stata_run_support import job_rel_path, write_json, write_text
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


def safe_output_filename(value: str) -> bool:
    if value == "":
        return False
    if "\\" in value:
        return False
    if value.startswith("~"):
        return False
    path = PurePosixPath(value)
    if path.is_absolute():
        return False
    parts = path.parts
    if not parts:
        return False
    if ".." in parts:
        return False
    if any(part in {"", ".", ".."} for part in parts):
        return False
    if any(part.startswith("~") for part in parts):
        return False
    return True


def output_kind(output: JsonObject) -> ArtifactKind:
    output_type = output.get("type", "")
    if output_type == "table":
        return ArtifactKind.STATA_EXPORT_TABLE
    if output_type in {"figure", "graph"}:
        return ArtifactKind.STATA_EXPORT_FIGURE
    if output_type == "log":
        return ArtifactKind.STATA_RESULT_LOG
    return ArtifactKind.STATA_RESULT_LOG


def declared_outputs(*, template_id: str, meta: JsonObject) -> tuple[JsonObject, ...]:
    raw = meta.get("outputs", [])
    if raw is None:
        return tuple()
    if not isinstance(raw, list):
        raise DoTemplateContractInvalidError(template_id=template_id, reason="meta.outputs_invalid")
    outputs: list[JsonObject] = []
    for item in raw:
        if isinstance(item, dict):
            outputs.append(item)
    return tuple(outputs)


def output_filename(*, template_id: str, output: JsonObject) -> str:
    filename = output.get("file", "")
    if not isinstance(filename, str) or not safe_output_filename(filename):
        raise DoTemplateContractInvalidError(
            template_id=template_id,
            reason="meta.output_file_invalid",
        )
    return filename


def write_artifact_text(
    *,
    template_id: str,
    job_id: str,
    run_id: str,
    path: Path,
    content: str,
) -> None:
    try:
        write_text(path, content)
    except OSError as e:
        extra = {
            "template_id": template_id,
            "job_id": job_id,
            "run_id": run_id,
            "path": str(path),
        }
        logger.warning(
            "SS_DO_TEMPLATE_ARTIFACT_WRITE_FAILED",
            extra=extra,
        )
        raise DoTemplateArtifactsWriteError(
            template_id=template_id,
            job_id=job_id,
            run_id=run_id,
            rel_path=str(path),
        ) from e


def write_artifact_json(
    *,
    template_id: str,
    job_id: str,
    run_id: str,
    path: Path,
    payload: JsonObject,
) -> None:
    try:
        write_json(path, payload)
    except OSError as e:
        extra = {
            "template_id": template_id,
            "job_id": job_id,
            "run_id": run_id,
            "path": str(path),
        }
        logger.warning(
            "SS_DO_TEMPLATE_ARTIFACT_WRITE_FAILED",
            extra=extra,
        )
        raise DoTemplateArtifactsWriteError(
            template_id=template_id,
            job_id=job_id,
            run_id=run_id,
            rel_path=str(path),
        ) from e


def artifact_ref(*, job_dir: Path, kind: ArtifactKind, path: Path) -> ArtifactRef:
    return ArtifactRef(kind=kind, rel_path=job_rel_path(job_dir=job_dir, path=path))


def copy_output_or_skip(*, src: Path, dst: Path) -> bool:
    try:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    except FileNotFoundError:
        return False
    return True


def append_artifact_if_missing(*, refs: list[ArtifactRef], ref: ArtifactRef) -> None:
    if any(existing.kind == ref.kind and existing.rel_path == ref.rel_path for existing in refs):
        return
    refs.append(ref)


def ensure_job_status(
    *,
    job_id: str,
    state_machine: JobStateMachine,
    job: Job,
    status: JobStatus,
) -> None:
    current = getattr(job, "status", None)
    if current is None or not isinstance(current, JobStatus):
        return
    if state_machine.ensure_transition(job_id=job_id, from_status=current, to_status=status):
        job.status = status
