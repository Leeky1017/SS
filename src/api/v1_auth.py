from __future__ import annotations

from datetime import datetime

from fastapi import Depends, Header

from src.api.deps import get_job_store, get_tenant_id
from src.domain.job_store import JobStore
from src.domain.upload_session_id import job_id_from_upload_session_id
from src.infra.auth_exceptions import (
    AuthBearerTokenInvalidError,
    AuthBearerTokenMissingError,
    AuthTokenForbiddenError,
    AuthTokenInvalidError,
)
from src.utils.time import utc_now


async def enforce_v1_job_bearer_auth(
    job_id: str | None = None,
    authorization: str | None = Header(default=None, alias="Authorization"),
    tenant_id: str = Depends(get_tenant_id),
    store: JobStore = Depends(get_job_store),
) -> None:
    if job_id is None:
        return
    if not job_id.startswith("job_tc_"):
        return
    job = store.load(tenant_id=tenant_id, job_id=job_id)
    required = getattr(job, "auth_token", None)
    if not isinstance(required, str) or required.strip() == "":
        return

    token = _bearer_token_or_raise(authorization)
    token_job_id = _token_job_id_or_raise(token)
    if token_job_id != job_id:
        raise AuthTokenForbiddenError()
    if token != required:
        raise AuthTokenInvalidError()
    if _is_expired(job_expires_at=getattr(job, "auth_expires_at", None), now=utc_now()):
        raise AuthTokenInvalidError()


async def enforce_v1_upload_session_bearer_auth(
    upload_session_id: str | None = None,
    authorization: str | None = Header(default=None, alias="Authorization"),
    tenant_id: str = Depends(get_tenant_id),
    store: JobStore = Depends(get_job_store),
) -> None:
    if upload_session_id is None:
        return
    try:
        job_id = job_id_from_upload_session_id(upload_session_id)
    except ValueError:
        return
    await enforce_v1_job_bearer_auth(
        job_id=job_id,
        authorization=authorization,
        tenant_id=tenant_id,
        store=store,
    )


def _bearer_token_or_raise(authorization: str | None) -> str:
    if authorization is None:
        raise AuthBearerTokenMissingError()
    normalized = authorization.strip()
    if normalized == "":
        raise AuthBearerTokenInvalidError(reason="empty")
    if not normalized.lower().startswith("bearer "):
        raise AuthBearerTokenInvalidError(reason="not_bearer")
    token = normalized[7:].strip()
    if token == "":
        raise AuthBearerTokenInvalidError(reason="empty_token")
    return token


def _token_job_id_or_raise(token: str) -> str:
    parts = token.split(".")
    if len(parts) != 3 or parts[0] != "ssv1":
        raise AuthTokenInvalidError()
    job_id = parts[1].strip()
    secret = parts[2].strip()
    if job_id == "" or secret == "":
        raise AuthTokenInvalidError()
    return job_id


def _is_expired(*, job_expires_at: object, now: datetime) -> bool:
    if not isinstance(job_expires_at, str) or job_expires_at.strip() == "":
        return True
    try:
        expires = datetime.fromisoformat(job_expires_at)
    except ValueError:
        return True
    return expires <= now
