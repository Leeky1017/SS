from __future__ import annotations

from collections.abc import Callable
from datetime import datetime

from src.domain.models import LLMPlan, PlanStep, PlanStepType
from src.domain.stata_dependency_checker import StataDependency
from src.utils.json_types import JsonObject


def declared_stata_dependencies(*, plan: LLMPlan) -> tuple[StataDependency, ...]:
    for step in plan.steps:
        if step.type != PlanStepType.GENERATE_STATA_DO:
            continue
        contract = step.params.get("template_contract")
        if not isinstance(contract, dict):
            return tuple()
        raw = contract.get("dependencies", [])
        if not isinstance(raw, list):
            return tuple()
        deps: list[StataDependency] = []
        for item in raw:
            if not isinstance(item, dict):
                continue
            pkg = item.get("pkg", "")
            source = item.get("source", "")
            purpose = item.get("purpose", "")
            if not isinstance(pkg, str) or pkg.strip() == "":
                continue
            if not isinstance(source, str) or source.strip() == "":
                continue
            deps.append(
                StataDependency(
                    pkg=pkg.strip(),
                    source=source.strip(),
                    purpose=purpose.strip() if isinstance(purpose, str) else "",
                )
            )
        return tuple(deps)
    return tuple()


def timeout_seconds_from_step(*, step: PlanStep) -> int | None:
    raw = step.params.get("timeout_seconds")
    if raw is None:
        return None
    if isinstance(raw, (dict, list)):
        return None
    try:
        seconds = int(raw)
    except (TypeError, ValueError):
        return None
    if seconds <= 0:
        return None
    return seconds


def cap_timeout_seconds(
    *,
    timeout_seconds: int | None,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
) -> int | None:
    if shutdown_deadline is None:
        return timeout_seconds

    remaining = int((shutdown_deadline - clock()).total_seconds())
    if remaining <= 0:
        remaining = 1

    if timeout_seconds is None:
        return remaining
    return min(timeout_seconds, remaining)


def dependency_error_details(*, missing: tuple[StataDependency, ...]) -> JsonObject:
    return {
        "missing_dependencies": [
            {"pkg": dep.pkg, "source": dep.source, "purpose": dep.purpose} for dep in missing
        ]
    }

