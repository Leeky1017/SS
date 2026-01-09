from __future__ import annotations

from src.infra.exceptions import SSError


class DraftConfirmBlockedError(SSError):
    def __init__(
        self,
        *,
        missing_question_ids: list[str],
        blocking_unknown_fields: list[str],
    ) -> None:
        parts: list[str] = []
        if len(missing_question_ids) > 0:
            joined = ", ".join(sorted(set(missing_question_ids)))
            parts.append(f"missing_answers=[{joined}]")
        if len(blocking_unknown_fields) > 0:
            joined = ", ".join(sorted(set(blocking_unknown_fields)))
            parts.append(f"unresolved_unknowns=[{joined}]")
        message = "; ".join(parts) if parts else "confirmation blocked"
        super().__init__(error_code="DRAFT_CONFIRM_BLOCKED", message=message, status_code=400)

