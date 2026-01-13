from __future__ import annotations

from fastapi import Depends, Header

from src.api.deps import get_config
from src.config import Config
from src.domain.admin_auth_service import AdminAuthService, AdminPrincipal
from src.domain.admin_token_store import AdminTokenStore
from src.domain.job_indexer import JobIndexer
from src.domain.task_code_store import TaskCodeStore
from src.infra.admin_exceptions import AdminBearerTokenInvalidError, AdminBearerTokenMissingError
from src.infra.file_admin_token_store import FileAdminTokenStore
from src.infra.file_job_indexer import FileJobIndexer
from src.infra.file_task_code_store import FileTaskCodeStore
from src.utils.time import utc_now


async def get_admin_token_store(config: Config = Depends(get_config)) -> AdminTokenStore:
    return FileAdminTokenStore(data_dir=config.admin_data_dir)


async def get_task_code_store(config: Config = Depends(get_config)) -> TaskCodeStore:
    return FileTaskCodeStore(data_dir=config.admin_data_dir)


async def get_job_indexer(config: Config = Depends(get_config)) -> JobIndexer:
    return FileJobIndexer(jobs_dir=config.jobs_dir)


async def get_admin_auth_service(
    config: Config = Depends(get_config),
    tokens: AdminTokenStore = Depends(get_admin_token_store),
) -> AdminAuthService:
    return AdminAuthService(
        expected_username=config.admin_username,
        expected_password=config.admin_password,
        tokens=tokens,
        now=utc_now,
    )


async def require_admin_principal(
    authorization: str | None = Header(default=None, alias="Authorization"),
    auth: AdminAuthService = Depends(get_admin_auth_service),
) -> AdminPrincipal:
    token = _bearer_token_or_raise(authorization)
    return auth.authenticate(token=token)


def _bearer_token_or_raise(authorization: str | None) -> str:
    if authorization is None:
        raise AdminBearerTokenMissingError()
    normalized = authorization.strip()
    if normalized == "":
        raise AdminBearerTokenInvalidError(reason="empty")
    if not normalized.lower().startswith("bearer "):
        raise AdminBearerTokenInvalidError(reason="not_bearer")
    token = normalized[7:].strip()
    if token == "":
        raise AdminBearerTokenInvalidError(reason="empty_token")
    return token
