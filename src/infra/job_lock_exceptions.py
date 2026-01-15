from __future__ import annotations

from src.infra.exceptions import SSError


class JobLockedError(SSError):
    def __init__(self, *, job_id: str, status: str, operation: str) -> None:
        super().__init__(
            error_code="JOB_LOCKED",
            message=f"job locked: {job_id} (status={status}, operation={operation})",
            status_code=409,
        )

