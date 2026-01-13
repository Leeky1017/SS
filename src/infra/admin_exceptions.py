from __future__ import annotations

from src.infra.exceptions import SSError


class AdminNotConfiguredError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="ADMIN_NOT_CONFIGURED",
            message="admin authentication is not configured",
            status_code=500,
        )


class AdminCredentialsInvalidError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="ADMIN_CREDENTIALS_INVALID",
            message="invalid admin credentials",
            status_code=401,
        )


class AdminBearerTokenMissingError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="ADMIN_BEARER_TOKEN_MISSING",
            message="missing Authorization: Bearer <token>",
            status_code=401,
        )


class AdminBearerTokenInvalidError(SSError):
    def __init__(self, *, reason: str) -> None:
        super().__init__(
            error_code="ADMIN_BEARER_TOKEN_INVALID",
            message=f"invalid Authorization header ({reason})",
            status_code=401,
        )


class AdminTokenInvalidError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="ADMIN_TOKEN_INVALID",
            message="admin token is invalid",
            status_code=403,
        )


class AdminTokenNotFoundError(SSError):
    def __init__(self, *, token_id: str) -> None:
        super().__init__(
            error_code="ADMIN_TOKEN_NOT_FOUND",
            message=f"admin token not found: {token_id}",
            status_code=404,
        )


class AdminStoreIOError(SSError):
    def __init__(self, *, operation: str, path: str) -> None:
        super().__init__(
            error_code="ADMIN_STORE_IO_ERROR",
            message=f"admin store io error ({operation}): {path}",
            status_code=500,
        )

