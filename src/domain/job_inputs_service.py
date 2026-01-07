from __future__ import annotations

import hashlib
import json
import logging
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import cast

from src.domain.dataset_preview import dataset_preview
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import Job, JobInputs
from src.infra.exceptions import JobStoreIOError
from src.infra.input_exceptions import (
    InputEmptyFileError,
    InputFilenameUnsafeError,
    InputParseFailedError,
    InputStorageFailedError,
    InputUnsupportedFormatError,
)
from src.utils.job_workspace import is_safe_path_segment
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)

_INPUTS_DIR = "inputs"
_MANIFEST_REL_PATH = f"{_INPUTS_DIR}/manifest.json"
_MANIFEST_SCHEMA_VERSION = 1


@dataclass(frozen=True)
class _UploadMeta:
    filename: str
    fmt: str
    stored_rel_path: str
    sha256: str
    fingerprint: str
    size_bytes: int


def _safe_filename(*, original_name: str | None, override_name: str | None) -> str:
    candidate = override_name if override_name is not None else original_name
    if candidate is None:
        raise InputFilenameUnsafeError(filename="")
    name = candidate.strip()
    if name == "" or not is_safe_path_segment(name):
        raise InputFilenameUnsafeError(filename=candidate)
    return name


def _format_from_filename(filename: str) -> tuple[str, str]:
    ext = Path(filename).suffix.lower()
    if ext == ".csv":
        return "csv", ext
    if ext in {".xls", ".xlsx"}:
        return "excel", ext
    if ext == ".dta":
        return "dta", ext
    raise InputUnsupportedFormatError(filename=filename)


def _sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _read_manifest_json(path: Path) -> JsonObject:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("manifest must be a JSON object")
    return cast(JsonObject, raw)


def _extract_primary_dataset_manifest(manifest: JsonObject) -> tuple[str, str, str]:
    primary = manifest.get("primary_dataset")
    if not isinstance(primary, dict):
        raise ValueError("manifest missing primary_dataset")
    rel_path = primary.get("rel_path")
    if not isinstance(rel_path, str) or rel_path.strip() == "":
        raise ValueError("manifest missing primary_dataset.rel_path")
    fmt = primary.get("format")
    if not isinstance(fmt, str) or fmt.strip() == "":
        raise ValueError("manifest missing primary_dataset.format")
    original_name = primary.get("original_name")
    if not isinstance(original_name, str) or original_name.strip() == "":
        original_name = rel_path
    return rel_path, fmt, original_name


def _upload_meta(*, filename: str, fmt: str, ext: str, data: bytes) -> _UploadMeta:
    sha256 = _sha256_hex(data)
    return _UploadMeta(
        filename=filename,
        fmt=fmt,
        stored_rel_path=f"{_INPUTS_DIR}/primary{ext}",
        sha256=sha256,
        fingerprint=f"sha256:{sha256}",
        size_bytes=len(data),
    )


class JobInputsService:
    def __init__(self, *, store: JobStore, workspace: JobWorkspaceStore):
        self._store = store
        self._workspace = workspace

    def _write_manifest(
        self,
        *,
        tenant_id: str,
        job_id: str,
        meta: _UploadMeta,
        content_type: str | None,
    ) -> None:
        manifest: JsonObject = cast(
            JsonObject,
            {
                "schema_version": _MANIFEST_SCHEMA_VERSION,
                "primary_dataset": {
                    "rel_path": meta.stored_rel_path,
                    "original_name": meta.filename,
                    "size_bytes": meta.size_bytes,
                    "sha256": meta.sha256,
                    "format": meta.fmt,
                    "uploaded_at": utc_now().isoformat(),
                    "content_type": content_type,
                },
            },
        )
        try:
            self._store.write_artifact_json(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=_MANIFEST_REL_PATH,
                payload=manifest,
            )
        except JobStoreIOError as e:
            logger.warning(
                "SS_INPUT_MANIFEST_WRITE_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "rel_path": _MANIFEST_REL_PATH,
                    "error_code": e.error_code,
                },
            )
            raise InputStorageFailedError(job_id=job_id, rel_path=_MANIFEST_REL_PATH) from e

    def _save_job_inputs(self, *, tenant_id: str, job: Job, fingerprint: str) -> None:
        if job.inputs is None:
            job.inputs = JobInputs()
        job.inputs.manifest_rel_path = _MANIFEST_REL_PATH
        job.inputs.fingerprint = fingerprint
        try:
            self._store.save(tenant_id=tenant_id, job=job)
        except JobStoreIOError as e:
            logger.warning(
                "SS_INPUT_JOB_UPDATE_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job.job_id, "error_code": e.error_code},
            )
            raise InputStorageFailedError(job_id=job.job_id, rel_path="job.json") from e

    def upload_primary_dataset(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        data: bytes,
        original_name: str | None,
        filename_override: str | None,
        content_type: str | None,
    ) -> JsonObject:
        filename = _safe_filename(original_name=original_name, override_name=filename_override)
        fmt, ext = _format_from_filename(filename)
        if len(data) == 0:
            logger.warning(
                "SS_INPUT_EMPTY_FILE",
                extra={"tenant_id": tenant_id, "job_id": job_id, "input_filename": filename},
            )
            raise InputEmptyFileError()
        meta = _upload_meta(filename=filename, fmt=fmt, ext=ext, data=data)

        logger.info(
            "SS_INPUT_UPLOAD_START",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "input_filename": filename,
                "format": fmt,
            },
        )
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        self._workspace.write_bytes(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=meta.stored_rel_path,
            data=data,
        )
        self._write_manifest(
            tenant_id=tenant_id,
            job_id=job_id,
            meta=meta,
            content_type=content_type,
        )
        self._save_job_inputs(tenant_id=tenant_id, job=job, fingerprint=meta.fingerprint)
        logger.info(
            "SS_INPUT_UPLOAD_DONE",
            extra={"tenant_id": tenant_id, "job_id": job_id, "fingerprint": meta.fingerprint},
        )
        return cast(
            JsonObject,
            {
                "job_id": job_id,
                "manifest_rel_path": _MANIFEST_REL_PATH,
                "fingerprint": meta.fingerprint,
            },
        )

    def _load_primary_manifest(
        self,
        *,
        tenant_id: str,
        job_id: str,
        manifest_rel_path: str,
    ) -> tuple[str, str, str]:
        try:
            manifest_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=manifest_rel_path,
            )
            manifest = _read_manifest_json(manifest_path)
            return _extract_primary_dataset_manifest(manifest)
        except (FileNotFoundError, OSError, json.JSONDecodeError, ValueError) as e:
            logger.warning(
                "SS_INPUT_MANIFEST_READ_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job_id, "rel_path": manifest_rel_path},
            )
            raise InputParseFailedError(
                filename=manifest_rel_path,
                detail="manifest invalid",
            ) from e

    def preview_primary_dataset(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        rows: int,
        columns: int,
    ) -> JsonObject:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        manifest_rel_path = None if job.inputs is None else job.inputs.manifest_rel_path
        if manifest_rel_path is None:
            raise InputParseFailedError(filename=_MANIFEST_REL_PATH, detail="manifest not set")

        dataset_rel_path, fmt, original_name = self._load_primary_manifest(
            tenant_id=tenant_id,
            job_id=job_id,
            manifest_rel_path=manifest_rel_path,
        )
        try:
            dataset_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=dataset_rel_path,
            )
            if dataset_path.stat().st_size == 0:
                raise InputEmptyFileError()
        except FileNotFoundError as e:
            raise InputParseFailedError(
                filename=original_name,
                detail="dataset not found",
            ) from e
        except OSError as e:
            raise InputParseFailedError(
                filename=original_name,
                detail="dataset not readable",
            ) from e

        try:
            preview = dataset_preview(path=dataset_path, fmt=fmt, rows=rows, columns=columns)
        except (UnicodeDecodeError, ValueError, OSError, ImportError, zipfile.BadZipFile) as e:
            logger.warning(
                "SS_INPUT_PREVIEW_PARSE_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "dataset_rel_path": dataset_rel_path,
                    "format": fmt,
                },
            )
            raise InputParseFailedError(filename=original_name) from e

        return cast(JsonObject, {"job_id": job_id, **preview})
