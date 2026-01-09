from __future__ import annotations

from src.infra.exceptions import SSError


class BundleNotFoundError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="BUNDLE_NOT_FOUND",
            message=f"bundle not found: {job_id}",
            status_code=404,
        )


class BundleFilesLimitExceededError(SSError):
    def __init__(self, *, max_files: int, actual_files: int):
        super().__init__(
            error_code="BUNDLE_FILES_LIMIT_EXCEEDED",
            message=f"bundle files limit exceeded: max={max_files} actual={actual_files}",
            status_code=400,
        )


class BundleCorruptedError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="BUNDLE_CORRUPTED",
            message=f"bundle corrupted: {job_id}",
            status_code=500,
        )

