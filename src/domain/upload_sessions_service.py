from __future__ import annotations

from src.config import Config
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.object_store import ObjectStore
from src.domain.upload_bundle_service import UploadBundleService
from src.domain.upload_session_store import UploadSessionStore
from src.domain.upload_sessions_finalizer import UploadSessionFinalizer
from src.domain.upload_sessions_issuer import UploadSessionIssuer
from src.domain.upload_sessions_refresher import UploadSessionRefresher
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID


class UploadSessionsService:
    def __init__(
        self,
        *,
        config: Config,
        store: JobStore,
        workspace: JobWorkspaceStore,
        object_store: ObjectStore,
        bundle_service: UploadBundleService,
        session_store: UploadSessionStore,
    ):
        self._issuer = UploadSessionIssuer(
            config=config,
            object_store=object_store,
            bundle_service=bundle_service,
            session_store=session_store,
        )
        self._refresher = UploadSessionRefresher(
            config=config,
            object_store=object_store,
            session_store=session_store,
        )
        self._finalizer = UploadSessionFinalizer(
            config=config,
            store=store,
            workspace=workspace,
            object_store=object_store,
            session_store=session_store,
        )

    def create_upload_session(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        bundle_id: str,
        file_id: str,
    ) -> JsonObject:
        return self._issuer.issue(
            tenant_id=tenant_id,
            job_id=job_id,
            bundle_id=bundle_id,
            file_id=file_id,
        )

    def refresh_multipart_urls(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        upload_session_id: str,
        part_numbers: list[int] | None,
    ) -> JsonObject:
        return self._refresher.refresh(
            tenant_id=tenant_id,
            upload_session_id=upload_session_id,
            part_numbers=part_numbers,
        )

    def finalize(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        upload_session_id: str,
        parts: list[dict[str, object]],
    ) -> JsonObject:
        return self._finalizer.finalize(
            tenant_id=tenant_id,
            upload_session_id=upload_session_id,
            parts=parts,
        )

