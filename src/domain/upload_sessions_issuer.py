from __future__ import annotations

import logging
import math
from datetime import timedelta
from typing import cast

from src.config import Config
from src.domain.object_store import ObjectStore
from src.domain.upload_bundle_service import Bundle, BundleFile, UploadBundleService
from src.domain.upload_session_id import build_upload_session_id
from src.domain.upload_session_store import UploadSessionStore
from src.domain.upload_sessions_models import UploadSessionRecord
from src.infra.upload_bundle_exceptions import BundleNotFoundError
from src.infra.upload_session_exceptions import (
    UploadBundleFileNotFoundError,
    UploadFileSizeLimitExceededError,
    UploadMultipartLimitExceededError,
    UploadSessionsLimitExceededError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


def _object_key(*, tenant_id: str, job_id: str, upload_session_id: str) -> str:
    return f"tenants/{tenant_id}/jobs/{job_id}/uploads/{upload_session_id}"


def _multipart_part_size(*, config: Config) -> int:
    requested = int(config.upload_multipart_part_size_bytes)
    min_size = int(config.upload_multipart_min_part_size_bytes)
    max_size = int(config.upload_multipart_max_part_size_bytes)
    return max(min_size, min(max_size, requested))


def _multipart_part_count(*, size_bytes: int, part_size: int) -> int:
    if size_bytes <= 0 or part_size <= 0:
        raise UploadMultipartLimitExceededError(reason="part_count_invalid")
    return int(math.ceil(size_bytes / part_size))


def _find_bundle_file(*, bundle: Bundle, file_id: str) -> BundleFile:
    for item in bundle.files:
        if item.file_id == file_id:
            return item
    raise UploadBundleFileNotFoundError(file_id=file_id)


class UploadSessionIssuer:
    def __init__(
        self,
        *,
        config: Config,
        object_store: ObjectStore,
        bundle_service: UploadBundleService,
        session_store: UploadSessionStore,
    ):
        self._config = config
        self._object_store = object_store
        self._bundle = bundle_service
        self._sessions = session_store

    def issue(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        bundle_id: str,
        file_id: str,
    ) -> JsonObject:
        now = utc_now()
        ttl_seconds = int(self._config.upload_presigned_url_ttl_seconds)
        expires_at = (now + timedelta(seconds=ttl_seconds)).isoformat()
        with self._sessions.lock_job(tenant_id=tenant_id, job_id=job_id):
            self._assert_session_limit(tenant_id=tenant_id, job_id=job_id, now=now)
            bundle = self._bundle_for_job(tenant_id=tenant_id, job_id=job_id, bundle_id=bundle_id)
            bundle_file = _find_bundle_file(bundle=bundle, file_id=file_id)
            self._assert_size_limit(size_bytes=int(bundle_file.size_bytes))
            upload_session_id = build_upload_session_id(job_id=job_id)
            object_key = _object_key(
                tenant_id=tenant_id,
                job_id=job_id,
                upload_session_id=upload_session_id,
            )
            payload, session = self._build_session(
                job_id=job_id,
                bundle_id=bundle_id,
                file_id=file_id,
                bundle_file=bundle_file,
                upload_session_id=upload_session_id,
                object_key=object_key,
                expires_at=expires_at,
                ttl_seconds=ttl_seconds,
                created_at=now.isoformat(),
            )
            self._sessions.save_session(tenant_id=tenant_id, job_id=job_id, session=session)
        logger.info(
            "SS_UPLOAD_SESSION_CREATE",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "upload_session_id": upload_session_id,
            },
        )
        return cast(
            JsonObject,
            {
                "upload_session_id": upload_session_id,
                "job_id": job_id,
                "file_id": file_id,
                "upload_strategy": session.upload_strategy,
                "expires_at": expires_at,
                **payload,
            },
        )

    def _bundle_for_job(self, *, tenant_id: str, job_id: str, bundle_id: str) -> Bundle:
        bundle = self._bundle.get_bundle(tenant_id=tenant_id, job_id=job_id)
        if bundle.bundle_id != bundle_id:
            raise BundleNotFoundError(job_id=job_id)
        return bundle

    def _assert_size_limit(self, *, size_bytes: int) -> None:
        if size_bytes <= int(self._config.upload_max_file_size_bytes):
            return
        raise UploadFileSizeLimitExceededError(
            max_size_bytes=int(self._config.upload_max_file_size_bytes),
            actual_size_bytes=int(size_bytes),
        )

    def _assert_session_limit(self, *, tenant_id: str, job_id: str, now) -> None:
        active = self._sessions.count_active_sessions(tenant_id=tenant_id, job_id=job_id, now=now)
        if active < int(self._config.upload_max_sessions_per_job):
            return
        raise UploadSessionsLimitExceededError(
            max_sessions=int(self._config.upload_max_sessions_per_job),
            actual_sessions=int(active),
        )

    def _build_session(
        self,
        *,
        job_id: str,
        bundle_id: str,
        file_id: str,
        bundle_file: BundleFile,
        upload_session_id: str,
        object_key: str,
        expires_at: str,
        ttl_seconds: int,
        created_at: str,
    ) -> tuple[dict[str, object], UploadSessionRecord]:
        size_bytes = int(bundle_file.size_bytes)
        if size_bytes >= int(self._config.upload_multipart_threshold_bytes):
            payload, upload_id, part_size, part_count = self._multipart_presigns(
                object_key=object_key,
                content_type=bundle_file.mime_type,
                ttl_seconds=ttl_seconds,
                size_bytes=size_bytes,
            )
            strategy = "multipart"
        else:
            payload = self._direct_presign(
                object_key=object_key,
                content_type=bundle_file.mime_type,
                ttl_seconds=ttl_seconds,
            )
            upload_id = None
            part_size = None
            part_count = None
            strategy = "direct"
        return payload, self._session_record(
            job_id=job_id,
            bundle_id=bundle_id,
            file_id=file_id,
            bundle_file=bundle_file,
            upload_session_id=upload_session_id,
            object_key=object_key,
            upload_strategy=strategy,
            upload_id=upload_id,
            part_size=part_size,
            part_count=part_count,
            size_bytes=size_bytes,
            created_at=created_at,
            expires_at=expires_at,
        )

    def _session_record(
        self,
        *,
        job_id: str,
        bundle_id: str,
        file_id: str,
        bundle_file: BundleFile,
        upload_session_id: str,
        object_key: str,
        upload_strategy: str,
        upload_id: str | None,
        part_size: int | None,
        part_count: int | None,
        size_bytes: int,
        created_at: str,
        expires_at: str,
    ) -> UploadSessionRecord:
        return UploadSessionRecord(
            upload_session_id=upload_session_id,
            job_id=job_id,
            bundle_id=bundle_id,
            file_id=file_id,
            role=bundle_file.role,
            original_name=bundle_file.filename,
            size_bytes=size_bytes,
            content_type=bundle_file.mime_type,
            upload_strategy=upload_strategy,
            object_key=object_key,
            upload_id=upload_id,
            part_size=part_size,
            part_count=part_count,
            created_at=created_at,
            expires_at=expires_at,
            finalized=None,
        )

    def _direct_presign(
        self,
        *,
        object_key: str,
        content_type: str | None,
        ttl_seconds: int,
    ) -> dict[str, object]:
        url = self._object_store.presign_put(
            object_key=object_key,
            expires_in_seconds=ttl_seconds,
            content_type=content_type,
        )
        return {"presigned_url": url}

    def _multipart_presigns(
        self,
        *,
        object_key: str,
        content_type: str | None,
        ttl_seconds: int,
        size_bytes: int,
    ) -> tuple[dict[str, object], str, int, int]:
        part_size = _multipart_part_size(config=self._config)
        part_count = _multipart_part_count(size_bytes=size_bytes, part_size=part_size)
        if part_count > int(self._config.upload_multipart_max_parts):
            raise UploadMultipartLimitExceededError(reason="max_parts_exceeded")
        upload_id = self._object_store.create_multipart_upload(
            object_key=object_key,
            content_type=content_type,
        )
        urls: list[dict[str, object]] = []
        for part_number in range(1, part_count + 1):
            url = self._object_store.presign_upload_part(
                object_key=object_key,
                upload_id=upload_id,
                part_number=part_number,
                expires_in_seconds=ttl_seconds,
            )
            urls.append({"part_number": part_number, "url": url})
        return {"part_size": part_size, "presigned_urls": urls}, upload_id, part_size, part_count
