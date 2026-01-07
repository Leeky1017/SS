from __future__ import annotations


def normalized_max_attempts(value: int) -> int:
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return 1
    if parsed <= 0:
        return 1
    return parsed


def backoff_seconds(*, attempt: int, base_seconds: float, max_seconds: float) -> float:
    try:
        base = float(base_seconds)
    except (TypeError, ValueError):
        base = 0.0
    try:
        cap = float(max_seconds)
    except (TypeError, ValueError):
        cap = 0.0
    if base <= 0:
        return 0.0
    if cap <= 0:
        cap = base
    seconds = base * (2 ** max(attempt - 1, 0))
    return float(min(seconds, cap))

