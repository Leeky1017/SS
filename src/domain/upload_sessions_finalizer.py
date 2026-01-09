from __future__ import annotations

import hashlib
import logging
from dataclasses import dataclass, replace
from datetime import datetime
from typing import cast

from src.config import Config
from src.domain.inputs_manifest import (
    MANIFEST_REL_PATH,
    PreparedDataset,
    inputs_fingerprint,
    prepare_dataset,
)
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.object_store import CompletedPart, ObjectStore
from src.domain.upload_session_id import job_id_from_upload_session_id
from src.domain.upload_session_store import UploadSessionStore
from src.domain.upload_sessions_manifest import (
    load_or_init_manifest,
    prepared_datasets_from_manifest,
    update_job_inputs,
    upsert_manifest_dataset,
)
from src.domain.upload_sessions_models import FinalizeSuccessPayload, UploadSessionRecord
from src.infra.object_store_exceptions import ObjectStoreOperationFailedError
from src.infra.upload_session_exceptions import (
    UploadPartsInvalidError,
    UploadSessionExpiredError,
    UploadSessionNotFoundError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class _FinalizePart:
    part_number: int
    etag: str
    sha256: str | None


def _normalize_etag(etag: str) -> str:
    candidate = etag.strip()
    if candidate.startswith('"') and candidate.endswith('"') and len(candidate) >= 2:
        candidate = candidate[1:-1]
    return candidate.strip()


def _failure(*, error_code: str, message: str, retryable: bool) -> JsonObject:
    return cast(
        JsonObject,
        {
            "success": False,
            "retryable": bool(retryable),
            "error_code": error_code,
            "message": message,
        },
    )


class UploadSessionFinalizer:
    def __init__(
        self,
        *,
        config: Config,
        store: JobStore,
        workspace: JobWorkspaceStore,
        object_store: ObjectStore,
        session_store: UploadSessionStore,
    ):
        self._config = config
        self._store = store
        self._workspace = workspace
        self._object_store = object_store
        self._sessions = session_store

    def finalize(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        upload_session_id: str,
        parts: list[dict[str, object]],
    ) -> JsonObject:
        job_id = self._job_id(upload_session_id=upload_session_id)
        now = utc_now()
        with self._sessions.lock_job(tenant_id=tenant_id, job_id=job_id):
            session = self._sessions.load_session(
                tenant_id=tenant_id,
                upload_session_id=upload_session_id,
            )
            self._assert_not_expired(session=session, now=now)
            if session.finalized is not None:
                return session.finalized.to_payload()
            parsed_parts = self._parse_parts(parts=parts, upload_strategy=session.upload_strategy)
            if session.upload_strategy == "multipart":
                incomplete = self._ensure_multipart_complete(session=session, parts=parsed_parts)
                if incomplete is not None:
                    return incomplete
            else:
                etag_failure = self._direct_etag_failure(session=session, part=parsed_parts[0])
                if etag_failure is not None:
                    return etag_failure
            data = self._read_object_bytes(object_key=session.object_key)
            if data is None:
                return _failure(
                    error_code="UPLOAD_INCOMPLETE",
                    message="uploaded object not found",
                    retryable=True,
                )
            if len(data) != int(session.size_bytes):
                return _failure(
                    error_code="UPLOAD_INCOMPLETE",
                    message="uploaded object size mismatch",
                    retryable=True,
                )
            sha256_hex = hashlib.sha256(data).hexdigest()
            if self._direct_sha256_mismatch(
                upload_strategy=session.upload_strategy,
                parts=parsed_parts,
                actual_sha256=sha256_hex,
            ):
                return _failure(
                    error_code="CHECKSUM_MISMATCH",
                    message="sha256 mismatch",
                    retryable=True,
                )
            finalized, updated_session = self._materialize_and_update_state(
                tenant_id=tenant_id,
                job_id=job_id,
                session=session,
                upload_session_id=upload_session_id,
                data=data,
                sha256_hex=sha256_hex,
                uploaded_at=now.isoformat(),
            )
            self._sessions.save_session(tenant_id=tenant_id, job_id=job_id, session=updated_session)
        logger.info(
            "SS_UPLOAD_SESSION_FINALIZE",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "upload_session_id": upload_session_id,
            },
        )
        return finalized.to_payload()

    def _job_id(self, *, upload_session_id: str) -> str:
        try:
            return job_id_from_upload_session_id(upload_session_id)
        except ValueError as exc:
            raise UploadSessionNotFoundError(upload_session_id=upload_session_id) from exc

    def _assert_not_expired(self, *, session: UploadSessionRecord, now: datetime) -> None:
        try:
            expires_at = datetime.fromisoformat(session.expires_at)
        except ValueError as exc:
            raise UploadSessionExpiredError(upload_session_id=session.upload_session_id) from exc
        if expires_at <= now:
            raise UploadSessionExpiredError(upload_session_id=session.upload_session_id)

    def _parse_parts(
        self,
        *,
        parts: list[dict[str, object]],
        upload_strategy: str,
    ) -> list[_FinalizePart]:
        if not isinstance(parts, list) or len(parts) == 0:
            raise UploadPartsInvalidError(reason="parts_empty")
        parsed: list[_FinalizePart] = []
        for item in parts:
            parsed.append(self._parse_part(item=item))
        if upload_strategy == "direct" and (len(parsed) != 1 or parsed[0].part_number != 1):
            raise UploadPartsInvalidError(reason="direct_requires_single_part_1")
        return parsed

    def _parse_part(self, *, item: object) -> _FinalizePart:
        if not isinstance(item, dict):
            raise UploadPartsInvalidError(reason="parts_not_objects")
        part_number = item.get("part_number")
        etag = item.get("etag")
        sha256 = item.get("sha256")
        if not isinstance(part_number, int) or part_number < 1:
            raise UploadPartsInvalidError(reason="part_number_invalid")
        if not isinstance(etag, str) or etag.strip() == "":
            raise UploadPartsInvalidError(reason="etag_invalid")
        if sha256 is not None and (not isinstance(sha256, str) or sha256.strip() == ""):
            raise UploadPartsInvalidError(reason="sha256_invalid")
        return _FinalizePart(part_number=part_number, etag=_normalize_etag(etag), sha256=sha256)

    def _direct_etag_failure(
        self,
        *,
        session: UploadSessionRecord,
        part: _FinalizePart,
    ) -> JsonObject | None:
        head = self._object_store.head_object(object_key=session.object_key)
        if head is None:
            return _failure(
                error_code="UPLOAD_INCOMPLETE",
                message="uploaded object not found",
                retryable=True,
            )
        if head.etag is None or head.etag.strip() == "":
            return None
        if _normalize_etag(head.etag) != part.etag:
            return _failure(
                error_code="UPLOAD_INCOMPLETE",
                message="uploaded object etag mismatch",
                retryable=True,
            )
        return None

    def _ensure_multipart_complete(
        self,
        *,
        session: UploadSessionRecord,
        parts: list[_FinalizePart],
    ) -> JsonObject | None:
        if session.part_count is None or session.upload_id is None:
            raise UploadPartsInvalidError(reason="multipart_session_missing_fields")
        unique_numbers = {p.part_number for p in parts}
        if len(unique_numbers) != len(parts):
            raise UploadPartsInvalidError(reason="duplicate_part_numbers")
        expected = set(range(1, int(session.part_count) + 1))
        if unique_numbers != expected:
            return _failure(
                error_code="UPLOAD_INCOMPLETE",
                message="multipart upload incomplete",
                retryable=True,
            )
        completed = [CompletedPart(part_number=p.part_number, etag=p.etag) for p in parts]
        try:
            self._object_store.complete_multipart_upload(
                object_key=session.object_key,
                upload_id=session.upload_id,
                parts=completed,
            )
        except (KeyError, ObjectStoreOperationFailedError):
            head = self._object_store.head_object(object_key=session.object_key)
            if head is not None:
                return None
            return _failure(
                error_code="UPLOAD_INCOMPLETE",
                message="multipart upload incomplete",
                retryable=True,
            )
        return None

    def _read_object_bytes(self, *, object_key: str) -> bytes | None:
        try:
            return self._object_store.read_bytes(object_key=object_key)
        except (KeyError, ObjectStoreOperationFailedError):
            return None

    def _direct_sha256_mismatch(
        self,
        *,
        upload_strategy: str,
        parts: list[_FinalizePart],
        actual_sha256: str,
    ) -> bool:
        if upload_strategy != "direct":
            return False
        expected = parts[0].sha256
        if expected is None:
            return False
        return expected != actual_sha256

    def _materialize_and_update_state(
        self,
        *,
        tenant_id: str,
        job_id: str,
        session: UploadSessionRecord,
        upload_session_id: str,
        data: bytes,
        sha256_hex: str,
        uploaded_at: str,
    ) -> tuple[FinalizeSuccessPayload, UploadSessionRecord]:
        dataset = self._prepare_dataset(session=session, data=data, uploaded_at=uploaded_at)
        self._write_dataset_bytes(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=dataset.rel_path,
            data=data,
        )
        self._persist_manifest_and_job_inputs(
            tenant_id=tenant_id,
            job_id=job_id,
            dataset=dataset,
        )
        finalized = FinalizeSuccessPayload(
            success=True,
            status="finalized",
            upload_session_id=upload_session_id,
            file_id=session.file_id,
            sha256=sha256_hex,
            size_bytes=len(data),
        )
        return finalized, replace(session, finalized=finalized)

    def _prepare_dataset(
        self,
        *,
        session: UploadSessionRecord,
        data: bytes,
        uploaded_at: str,
    ) -> PreparedDataset:
        return prepare_dataset(
            data=data,
            original_name=session.original_name,
            filename_override=None,
            role=session.role,
            content_type=session.content_type,
            uploaded_at=uploaded_at,
        )

    def _write_dataset_bytes(
        self,
        *,
        tenant_id: str,
        job_id: str,
        rel_path: str,
        data: bytes,
    ) -> None:
        self._workspace.write_bytes(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=rel_path,
            data=data,
        )

    def _persist_manifest_and_job_inputs(
        self,
        *,
        tenant_id: str,
        job_id: str,
        dataset: PreparedDataset,
    ) -> str:
        manifest = load_or_init_manifest(
            workspace=self._workspace,
            tenant_id=tenant_id,
            job_id=job_id,
        )
        updated_manifest = upsert_manifest_dataset(manifest=manifest, dataset=dataset)
        self._store.write_artifact_json(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=MANIFEST_REL_PATH,
            payload=updated_manifest,
        )
        fingerprint = inputs_fingerprint(
            datasets=prepared_datasets_from_manifest(manifest=updated_manifest)
        )
        update_job_inputs(
            store=self._store,
            tenant_id=tenant_id,
            job_id=job_id,
            dataset_rel_path=dataset.rel_path,
            fingerprint=fingerprint,
        )
        return fingerprint
