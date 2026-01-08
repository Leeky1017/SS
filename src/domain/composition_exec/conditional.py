from __future__ import annotations

from collections.abc import Mapping

from src.domain.models import PlanStep
from src.infra.plan_exceptions import PlanCompositionInvalidError


def conditional_decision_or_none(*, step: PlanStep) -> dict[str, object] | None:
    raw = step.params.get("condition")
    if not isinstance(raw, Mapping):
        return None
    predicate = raw.get("predicate")
    true_steps = raw.get("true_steps")
    false_steps = raw.get("false_steps")
    op = ""
    if isinstance(predicate, Mapping):
        op_obj = predicate.get("op")
        op = op_obj if isinstance(op_obj, str) else ""
    if op not in {"always_true", "always_false"}:
        raise PlanCompositionInvalidError(reason="predicate_unsupported", step_id=step.step_id)
    if not isinstance(true_steps, list) or not isinstance(false_steps, list):
        raise PlanCompositionInvalidError(reason="conditional_steps_missing", step_id=step.step_id)
    truthy = op == "always_true"
    return {
        "type": "conditional",
        "step_id": step.step_id,
        "predicate": {"op": op},
        "result": truthy,
        "selected_branch": "true" if truthy else "false",
        "true_steps": [s for s in true_steps if isinstance(s, str) and s.strip() != ""],
        "false_steps": [s for s in false_steps if isinstance(s, str) and s.strip() != ""],
    }


def apply_conditional_skip(
    *,
    step: PlanStep,
    decision: Mapping[str, object],
    steps_by_id: Mapping[str, PlanStep],
) -> dict[str, str]:
    selected_branch = decision.get("selected_branch")
    if selected_branch not in {"true", "false"}:
        raise PlanCompositionInvalidError(
            reason="conditional_decision_invalid",
            step_id=step.step_id,
        )
    true_steps = _ids(decision.get("true_steps"))
    false_steps = _ids(decision.get("false_steps"))
    if len(true_steps & false_steps) > 0:
        raise PlanCompositionInvalidError(reason="conditional_branch_overlap", step_id=step.step_id)
    for sid in true_steps | false_steps:
        if sid not in steps_by_id:
            raise PlanCompositionInvalidError(
                reason="conditional_unknown_step",
                step_id=step.step_id,
            )
    skipped = false_steps if selected_branch == "true" else true_steps
    return {sid: f"conditional_branch_not_selected (by {step.step_id})" for sid in skipped}


def ensure_no_depends_on_skipped(*, step: PlanStep, skip_reason: Mapping[str, str]) -> None:
    for dep in step.depends_on:
        if dep in skip_reason:
            raise PlanCompositionInvalidError(
                reason="depends_on_skipped_step",
                step_id=step.step_id,
            )


def _ids(value: object) -> set[str]:
    if not isinstance(value, list):
        return set()
    out: set[str] = set()
    for item in value:
        if isinstance(item, str) and item.strip() != "":
            out.add(item.strip())
    return out
