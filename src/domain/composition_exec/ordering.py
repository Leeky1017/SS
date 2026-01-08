from __future__ import annotations

from collections.abc import Mapping

from src.domain.models import LLMPlan
from src.infra.plan_exceptions import PlanCompositionInvalidError
from src.utils.job_workspace import is_safe_path_segment


def validate_step_ids(*, plan: LLMPlan) -> None:
    for step in plan.steps:
        if not is_safe_path_segment(step.step_id):
            raise PlanCompositionInvalidError(reason="unsafe_step_id", step_id=step.step_id)


def toposort(*, plan: LLMPlan) -> list[str]:
    deps_by_step_id = {step.step_id: list(step.depends_on) for step in plan.steps}
    step_ids = [step.step_id for step in plan.steps]
    return _toposort(step_ids=step_ids, deps_by_step_id=deps_by_step_id)


def _toposort(*, step_ids: list[str], deps_by_step_id: Mapping[str, list[str]]) -> list[str]:
    pending: dict[str, set[str]] = {sid: set(deps_by_step_id.get(sid, [])) for sid in step_ids}
    order: list[str] = []
    ready = [sid for sid in step_ids if len(pending.get(sid, set())) == 0]
    while ready:
        current = ready.pop()
        order.append(current)
        for sid, deps in pending.items():
            if current not in deps:
                continue
            deps.remove(current)
            if len(deps) == 0 and sid not in order and sid not in ready:
                ready.append(sid)
    if len(order) != len(step_ids):
        raise PlanCompositionInvalidError(reason="dependency_cycle")
    return order
