from __future__ import annotations

import logging
from dataclasses import replace
from datetime import datetime, timedelta
from typing import cast

from src.config import Config
from src.domain.object_store import ObjectStore
from src.domain.upload_session_id import job_id_from_upload_session_id
from src.domain.upload_session_store import UploadSessionStore
from src.domain.upload_sessions_models import UploadSessionRecord
from src.infra.upload_session_exceptions import (
    UploadPartsInvalidError,
    UploadSessionExpiredError,
    UploadSessionNotFoundError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


class UploadSessionRefresher:
    def __init__(
        self,
        *,
        config: Config,
        object_store: ObjectStore,
        session_store: UploadSessionStore,
    ):
        self._config = config
        self._object_store = object_store
        self._sessions = session_store

    def refresh(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        upload_session_id: str,
        part_numbers: list[int] | None,
    ) -> JsonObject:
        job_id = self._job_id(upload_session_id=upload_session_id)
        now = utc_now()
        ttl_seconds = int(self._config.upload_presigned_url_ttl_seconds)
        new_expires_at = (now + timedelta(seconds=ttl_seconds)).isoformat()
        with self._sessions.lock_job(tenant_id=tenant_id, job_id=job_id):
            session = self._sessions.load_session(
                tenant_id=tenant_id,
                upload_session_id=upload_session_id,
            )
            self._assert_multipart(session=session)
            self._assert_not_expired(session=session, now=now)
            requested = self._requested_parts(session=session, part_numbers=part_numbers)
            urls = self._refresh_parts(
                session=session,
                requested=requested,
                ttl_seconds=ttl_seconds,
            )
            session = replace(session, expires_at=new_expires_at)
            self._sessions.save_session(tenant_id=tenant_id, job_id=job_id, session=session)
        logger.info(
            "SS_UPLOAD_SESSION_REFRESH",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "upload_session_id": upload_session_id,
            },
        )
        return cast(
            JsonObject,
            {"upload_session_id": upload_session_id, "parts": urls, "expires_at": new_expires_at},
        )

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

    def _assert_multipart(self, *, session: UploadSessionRecord) -> None:
        if session.upload_strategy != "multipart":
            raise UploadPartsInvalidError(reason="refresh_requires_multipart")
        if session.part_count is None or session.upload_id is None:
            raise UploadPartsInvalidError(reason="multipart_session_missing_fields")

    def _requested_parts(
        self,
        *,
        session: UploadSessionRecord,
        part_numbers: list[int] | None,
    ) -> list[int]:
        if session.part_count is None:
            raise UploadPartsInvalidError(reason="multipart_missing_part_count")
        if part_numbers is None:
            requested = list(range(1, session.part_count + 1))
        else:
            requested = sorted({int(n) for n in part_numbers})
        if len(requested) == 0:
            raise UploadPartsInvalidError(reason="part_numbers_empty")
        if any(n < 1 or n > session.part_count for n in requested):
            raise UploadPartsInvalidError(reason="part_number_out_of_range")
        return requested

    def _refresh_parts(
        self,
        *,
        session: UploadSessionRecord,
        requested: list[int],
        ttl_seconds: int,
    ) -> list[dict[str, object]]:
        if session.upload_id is None:
            raise UploadPartsInvalidError(reason="multipart_missing_upload_id")
        refreshed: list[dict[str, object]] = []
        for part_number in requested:
            url = self._object_store.presign_upload_part(
                object_key=session.object_key,
                upload_id=session.upload_id,
                part_number=part_number,
                expires_in_seconds=ttl_seconds,
            )
            refreshed.append({"part_number": part_number, "url": url})
        return refreshed
