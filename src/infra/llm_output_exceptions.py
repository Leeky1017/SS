from __future__ import annotations

from src.infra.exceptions import SSError


class LLMResponseInvalidError(SSError):
    def __init__(self, *, job_id: str) -> None:
        super().__init__(
            error_code="LLM_RESPONSE_INVALID",
            message=f"llm response invalid: {job_id}",
            status_code=502,
        )

