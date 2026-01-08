from __future__ import annotations

from src.infra.plan_exceptions import PlanCompositionInvalidError


def step_run_id(*, pipeline_run_id: str, step_id: str) -> str:
    value = f"{pipeline_run_id}__{step_id}"
    if value.strip() == "" or "/" in value or "\\" in value:
        raise PlanCompositionInvalidError(reason="unsafe_step_run_id", step_id=step_id)
    return value

