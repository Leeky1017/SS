from __future__ import annotations

from src.infra.exceptions import SSError


class StructuredSSError(SSError):
    def __init__(
        self,
        *,
        error_code: str,
        message: str,
        status_code: int = 400,
        details: dict[str, object] | None = None,
    ) -> None:
        super().__init__(error_code=error_code, message=message, status_code=status_code)
        self.details = {} if details is None else dict(details)

