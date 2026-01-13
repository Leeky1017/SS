from __future__ import annotations

from src.infra.exceptions import SSError


class TaskCodeNotFoundError(SSError):
    def __init__(self, *, code_id: str) -> None:
        super().__init__(
            error_code="TASK_CODE_NOT_FOUND",
            message=f"task code not found: {code_id}",
            status_code=404,
        )


class TaskCodeStoreIOError(SSError):
    def __init__(self, *, operation: str, path: str) -> None:
        super().__init__(
            error_code="TASK_CODE_STORE_IO_ERROR",
            message=f"task code store io error ({operation}): {path}",
            status_code=500,
        )


class TaskCodeDataCorruptedError(SSError):
    def __init__(self, *, path: str) -> None:
        super().__init__(
            error_code="TASK_CODE_DATA_CORRUPTED",
            message=f"task code data corrupted: {path}",
            status_code=500,
        )

