from __future__ import annotations

import logging
from collections.abc import Sequence
from dataclasses import dataclass
from typing import cast
from zipfile import BadZipFile

from src.domain.dataset_preview import dataset_preview_with_options
from src.domain.inputs_manifest import (
    MANIFEST_REL_PATH,
    ROLE_PRIMARY_DATASET,
    PreparedDataset,
    inputs_fingerprint,
    manifest_payload,
    prepare_dataset,
    primary_dataset_details,
    primary_dataset_excel_options,
    read_manifest_json,
)
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import ArtifactKind, ArtifactRef, Job, JobInputs, JobStatus
from src.infra.exceptions import JobStoreIOError
from src.infra.input_exceptions import (
    InputDatasetKeyConflictError,
    InputEmptyFileError,
    InputParseFailedError,
    InputPrimaryDatasetMissingError,
    InputPrimaryDatasetMultipleError,
    InputStorageFailedError,
)
from src.infra.job_lock_exceptions import JobLockedError
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)

@dataclass(frozen=True)
class DatasetUpload:
    role: str
    data: bytes
    original_name: str | None
    filename_override: str | None
    content_type: str | None


class JobInputsService:
    def __init__(self, *, store: JobStore, workspace: JobWorkspaceStore):
        self._store = store
        self._workspace = workspace

    def _write_manifest(self, *, tenant_id: str, job_id: str, manifest: JsonObject) -> None:
        try:
            self._store.write_artifact_json(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=MANIFEST_REL_PATH,
                payload=manifest,
            )
        except JobStoreIOError as e:
            logger.warning(
                "SS_INPUT_MANIFEST_WRITE_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "rel_path": MANIFEST_REL_PATH,
                    "error_code": e.error_code,
                },
            )
            raise InputStorageFailedError(job_id=job_id, rel_path=MANIFEST_REL_PATH) from e

    def _index_input_artifacts(self, *, job: Job, datasets: Sequence[PreparedDataset]) -> None:
        known = {(ref.kind, ref.rel_path) for ref in job.artifacts_index}
        manifest_ref = ArtifactRef(
            kind=ArtifactKind.INPUTS_MANIFEST,
            rel_path=MANIFEST_REL_PATH,
        )
        key = (manifest_ref.kind, manifest_ref.rel_path)
        if key not in known:
            job.artifacts_index.append(manifest_ref)
            known.add(key)
        for dataset in datasets:
            ref = ArtifactRef(
                kind=ArtifactKind.INPUTS_DATASET,
                rel_path=dataset.rel_path,
            )
            key = (ref.kind, ref.rel_path)
            if key in known:
                continue
            job.artifacts_index.append(ref)
            known.add(key)

    def _save_job_inputs(
        self, *, tenant_id: str, job: Job, fingerprint: str, datasets: Sequence[PreparedDataset]
    ) -> None:
        if job.inputs is None:
            job.inputs = JobInputs()
        job.inputs.manifest_rel_path = MANIFEST_REL_PATH
        job.inputs.fingerprint = fingerprint
        self._index_input_artifacts(job=job, datasets=datasets)
        try:
            self._store.save(tenant_id=tenant_id, job=job)
        except JobStoreIOError as e:
            logger.warning(
                "SS_INPUT_JOB_UPDATE_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job.job_id, "error_code": e.error_code},
            )
            raise InputStorageFailedError(job_id=job.job_id, rel_path="job.json") from e

    def _validate_dataset_set(self, *, datasets: Sequence[PreparedDataset]) -> None:
        keys: set[str] = set()
        for dataset in datasets:
            if dataset.dataset_key in keys:
                raise InputDatasetKeyConflictError(dataset_key=dataset.dataset_key)
            keys.add(dataset.dataset_key)

        primary = [dataset for dataset in datasets if dataset.role == ROLE_PRIMARY_DATASET]
        if len(primary) == 0:
            raise InputPrimaryDatasetMissingError()
        if len(primary) > 1:
            raise InputPrimaryDatasetMultipleError(count=len(primary))

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
        return self.upload_datasets(
            tenant_id=tenant_id,
            job_id=job_id,
            uploads=[
                DatasetUpload(
                    role=ROLE_PRIMARY_DATASET,
                    data=data,
                    original_name=original_name,
                    filename_override=filename_override,
                    content_type=content_type,
                )
            ],
        )

    def _prepare_datasets(
        self, *, tenant_id: str, job_id: str, uploads: Sequence[DatasetUpload]
    ) -> list[PreparedDataset]:
        prepared: list[PreparedDataset] = []
        uploaded_at = utc_now().isoformat()
        for upload in uploads:
            if len(upload.data) == 0:
                logger.warning(
                    "SS_INPUT_EMPTY_FILE",
                    extra={
                        "tenant_id": tenant_id,
                        "job_id": job_id,
                        "input_filename": upload.original_name,
                        "role": upload.role,
                    },
                )
                raise InputEmptyFileError()
            prepared.append(
                prepare_dataset(
                    data=upload.data,
                    original_name=upload.original_name,
                    filename_override=upload.filename_override,
                    role=upload.role,
                    content_type=upload.content_type,
                    uploaded_at=uploaded_at,
                )
            )
        return prepared

    def _persist_datasets(
        self, *, tenant_id: str, job_id: str, datasets: Sequence[PreparedDataset]
    ) -> None:
        for dataset in datasets:
            self._workspace.write_bytes(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=dataset.rel_path,
                data=dataset.data,
            )
        self._write_manifest(
            tenant_id=tenant_id,
            job_id=job_id,
            manifest=manifest_payload(datasets=datasets),
        )

    def upload_datasets(
        self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str, uploads: Sequence[DatasetUpload]
    ) -> JsonObject:
        if len(uploads) == 0:
            raise InputParseFailedError(filename=MANIFEST_REL_PATH, detail="no datasets uploaded")

        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if job.status in {
            JobStatus.CONFIRMED, JobStatus.QUEUED, JobStatus.RUNNING,
            JobStatus.SUCCEEDED, JobStatus.FAILED,
        }:
            raise JobLockedError(job_id=job_id, status=job.status.value, operation="inputs.upload")

        prepared = self._prepare_datasets(tenant_id=tenant_id, job_id=job_id, uploads=uploads)
        self._validate_dataset_set(datasets=prepared)
        fingerprint = inputs_fingerprint(datasets=prepared)
        logger.info(
            "SS_INPUT_UPLOAD_START",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "datasets": len(prepared),
                "fingerprint": fingerprint,
            },
        )

        self._persist_datasets(tenant_id=tenant_id, job_id=job_id, datasets=prepared)
        self._save_job_inputs(
            tenant_id=tenant_id,
            job=job,
            fingerprint=fingerprint,
            datasets=prepared,
        )
        logger.info(
            "SS_INPUT_UPLOAD_DONE",
            extra={"tenant_id": tenant_id, "job_id": job_id, "datasets": len(prepared)},
        )
        payload = dict(job_id=job_id, manifest_rel_path=MANIFEST_REL_PATH, fingerprint=fingerprint)
        return cast(JsonObject, payload)

    def _load_primary_manifest(
        self, *, tenant_id: str, job_id: str, manifest_rel_path: str
    ) -> tuple[str, str, str, str | None, bool | None]:
        try:
            manifest_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=manifest_rel_path,
            )
            manifest = read_manifest_json(manifest_path)
            dataset_rel_path, fmt, original_name = primary_dataset_details(manifest)
            sheet_name, header_row = primary_dataset_excel_options(manifest)
            return dataset_rel_path, fmt, original_name, sheet_name, header_row
        except (FileNotFoundError, OSError, ValueError) as e:
            logger.warning(
                "SS_INPUT_MANIFEST_READ_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job_id, "rel_path": manifest_rel_path},
            )
            raise InputParseFailedError(
                filename=manifest_rel_path,
                detail="manifest invalid",
            ) from e

    def preview_primary_dataset(
        self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str, rows: int, columns: int
    ) -> JsonObject:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        manifest_rel_path = None if job.inputs is None else job.inputs.manifest_rel_path
        if manifest_rel_path is None:
            raise InputParseFailedError(filename=MANIFEST_REL_PATH, detail="manifest not set")
        dataset_rel_path, fmt, original_name, sheet_name, header_row = self._load_primary_manifest(
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
            raise InputParseFailedError(filename=original_name, detail="dataset not found") from e
        except OSError as e:
            raise InputParseFailedError(filename=original_name, detail="dataset unreadable") from e

        try:
            preview = dataset_preview_with_options(
                path=dataset_path, fmt=fmt, rows=rows, columns=columns,
                sheet_name=sheet_name, header_row=header_row
            )
        except (KeyError, UnicodeDecodeError, ValueError, OSError, ImportError, BadZipFile) as e:
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
