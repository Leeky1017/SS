from __future__ import annotations

from src.domain.draft_confirm_blocking import confirm_blockers
from src.domain.job_store import JobStore
from src.infra.draft_exceptions import DraftConfirmBlockedError
from src.utils.json_types import JsonValue
from src.utils.tenancy import DEFAULT_TENANT_ID


def validate_confirm_not_blocked(
    *,
    store: JobStore,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
    answers: dict[str, JsonValue] | None,
) -> None:
    job = store.load(tenant_id=tenant_id, job_id=job_id)
    missing_question_ids, blocking_unknown_fields = confirm_blockers(
        draft=job.draft,
        answers={} if answers is None else dict(answers),
    )
    if len(missing_question_ids) == 0 and len(blocking_unknown_fields) == 0:
        return
    raise DraftConfirmBlockedError(
        missing_question_ids=missing_question_ids,
        blocking_unknown_fields=blocking_unknown_fields,
    )
