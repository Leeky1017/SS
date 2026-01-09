from __future__ import annotations

from src.infra.exceptions import SSError


class ObjectStoreConfigurationError(SSError):
    def __init__(self, *, message: str):
        super().__init__(
            error_code="OBJECT_STORE_CONFIG_INVALID",
            message=message,
            status_code=500,
        )


class ObjectStoreOperationFailedError(SSError):
    def __init__(self, *, operation: str):
        super().__init__(
            error_code="OBJECT_STORE_OPERATION_FAILED",
            message=f"object store operation failed: {operation}",
            status_code=502,
        )

