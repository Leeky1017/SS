from __future__ import annotations

from datetime import datetime
from typing import Callable

from src.domain.models import PlanStep


def step_timeout_seconds(
    *,
    step: PlanStep,
    shutdown_deadline: datetime | None,
    clock: Callable[[], datetime],
) -> int | None:
    timeout_seconds = _parse_timeout_seconds(step=step)
    if shutdown_deadline is None:
        return timeout_seconds
    remaining = int((shutdown_deadline - clock()).total_seconds())
    if remaining <= 0:
        remaining = 1
    if timeout_seconds is None:
        return remaining
    return min(timeout_seconds, remaining)


def _parse_timeout_seconds(*, step: PlanStep) -> int | None:
    raw = step.params.get("timeout_seconds")
    if raw is None or isinstance(raw, (dict, list)):
        return None
    try:
        seconds = int(raw)
    except (TypeError, ValueError):
        return None
    if seconds <= 0:
        return None
    return seconds

