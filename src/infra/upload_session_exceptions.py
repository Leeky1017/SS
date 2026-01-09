from __future__ import annotations

from src.infra.exceptions import SSError


class UploadSessionNotFoundError(SSError):
    def __init__(self, *, upload_session_id: str):
        super().__init__(
            error_code="UPLOAD_SESSION_NOT_FOUND",
            message=f"upload session not found: {upload_session_id}",
            status_code=404,
        )


class UploadSessionExpiredError(SSError):
    def __init__(self, *, upload_session_id: str):
        super().__init__(
            error_code="UPLOAD_SESSION_EXPIRED",
            message=f"upload session expired: {upload_session_id}",
            status_code=400,
        )


class UploadSessionCorruptedError(SSError):
    def __init__(self, *, upload_session_id: str):
        super().__init__(
            error_code="UPLOAD_SESSION_CORRUPTED",
            message=f"upload session corrupted: {upload_session_id}",
            status_code=500,
        )


class UploadFileSizeLimitExceededError(SSError):
    def __init__(self, *, max_size_bytes: int, actual_size_bytes: int):
        super().__init__(
            error_code="UPLOAD_FILE_SIZE_LIMIT_EXCEEDED",
            message=f"upload file too large: max={max_size_bytes} actual={actual_size_bytes}",
            status_code=400,
        )


class UploadSessionsLimitExceededError(SSError):
    def __init__(self, *, max_sessions: int, actual_sessions: int):
        super().__init__(
            error_code="UPLOAD_SESSIONS_LIMIT_EXCEEDED",
            message=f"upload sessions limit exceeded: max={max_sessions} actual={actual_sessions}",
            status_code=400,
        )


class UploadMultipartLimitExceededError(SSError):
    def __init__(self, *, reason: str):
        super().__init__(
            error_code="UPLOAD_MULTIPART_LIMIT_EXCEEDED",
            message=f"multipart constraints exceeded: {reason}",
            status_code=400,
        )


class UploadPartsInvalidError(SSError):
    def __init__(self, *, reason: str):
        super().__init__(
            error_code="UPLOAD_PARTS_INVALID",
            message=f"upload parts invalid: {reason}",
            status_code=400,
        )


class UploadBundleFileNotFoundError(SSError):
    def __init__(self, *, file_id: str):
        super().__init__(
            error_code="FILE_NOT_FOUND",
            message=f"bundle file not found: {file_id}",
            status_code=404,
        )

