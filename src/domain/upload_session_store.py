from __future__ import annotations

from datetime import datetime
from typing import ContextManager, Protocol

from src.domain.upload_sessions_models import UploadSessionRecord
from src.utils.tenancy import DEFAULT_TENANT_ID


class UploadSessionStore(Protocol):
    def lock_job(
        self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str
    ) -> ContextManager[None]: ...

    def count_active_sessions(
        self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str, now: datetime
    ) -> int: ...

    def load_session(
        self, *, tenant_id: str = DEFAULT_TENANT_ID, upload_session_id: str
    ) -> UploadSessionRecord: ...

    def save_session(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        session: UploadSessionRecord,
    ) -> None: ...
