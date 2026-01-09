from __future__ import annotations

from src.domain.models import JobConfirmation
from src.domain.plan_service import PlanService
from src.domain.variable_corrections import (
    apply_variable_corrections_dict_values,
    clean_variable_corrections,
)
from src.utils.json_types import JsonValue
from src.utils.tenancy import DEFAULT_TENANT_ID


def freeze_plan_for_run(
    *,
    plan_service: PlanService,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
    notes: str | None,
    variable_corrections: dict[str, str] | None,
    default_overrides: dict[str, JsonValue] | None,
    answers: dict[str, JsonValue] | None,
    expert_suggestions_feedback: dict[str, JsonValue] | None,
) -> None:
    cleaned: dict[str, str]
    if variable_corrections is None:
        cleaned = {}
    else:
        cleaned = clean_variable_corrections(variable_corrections)

    overrides: dict[str, JsonValue]
    if default_overrides is None:
        overrides = {}
    else:
        overrides = dict(default_overrides)
    if len(cleaned) > 0 and len(overrides) > 0:
        overrides = apply_variable_corrections_dict_values(overrides, cleaned)
    plan_service.freeze_plan(
        tenant_id=tenant_id,
        job_id=job_id,
        confirmation=JobConfirmation(
            notes=notes,
            variable_corrections=cleaned,
            answers={} if answers is None else dict(answers),
            default_overrides=overrides,
            expert_suggestions_feedback={}
            if expert_suggestions_feedback is None
            else dict(expert_suggestions_feedback),
        ),
    )
