from __future__ import annotations

from dataclasses import dataclass


@dataclass
class SSError(Exception):
    error_code: str
    message: str
    status_code: int = 400

    def to_dict(self) -> dict[str, str]:
        return {"error_code": self.error_code, "message": self.message}


class JobNotFoundError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_NOT_FOUND",
            message=f"job not found: {job_id}",
            status_code=404,
        )


class JobAlreadyExistsError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_ALREADY_EXISTS",
            message=f"job already exists: {job_id}",
            status_code=409,
        )


class JobDataCorruptedError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_DATA_CORRUPTED",
            message=f"job data corrupted: {job_id}",
            status_code=500,
        )


class JobStoreIOError(SSError):
    def __init__(self, *, operation: str, job_id: str):
        super().__init__(
            error_code="JOB_STORE_IO_ERROR",
            message=f"job store io error ({operation}): {job_id}",
            status_code=500,
        )
