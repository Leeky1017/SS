from __future__ import annotations

from src.infra.exceptions import SSError


class AuthBearerTokenMissingError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="AUTH_BEARER_TOKEN_MISSING",
            message="missing Authorization: Bearer <token>",
            status_code=401,
        )


class AuthBearerTokenInvalidError(SSError):
    def __init__(self, *, reason: str) -> None:
        super().__init__(
            error_code="AUTH_BEARER_TOKEN_INVALID",
            message=f"invalid Authorization header ({reason})",
            status_code=401,
        )


class AuthTokenInvalidError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="AUTH_TOKEN_INVALID",
            message="token is invalid",
            status_code=403,
        )


class AuthTokenForbiddenError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="AUTH_TOKEN_FORBIDDEN",
            message="token does not authorize this job",
            status_code=403,
        )

class TaskCodeInvalidError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="TASK_CODE_INVALID",
            message="task_code must be a non-empty string",
            status_code=400,
        )


class TaskCodeRedeemConflictError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="TASK_CODE_REDEEM_CONFLICT",
            message="task_code redemption conflicted with an existing job",
            status_code=409,
        )
