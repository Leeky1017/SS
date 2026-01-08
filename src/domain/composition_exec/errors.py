from __future__ import annotations

from src.domain.stata_runner import RunError, RunResult


def error_or_default(*, result: RunResult) -> RunError:
    if result.error is not None:
        return result.error
    return RunError(error_code="STATA_NONZERO_EXIT", message="step failed without error detail")

