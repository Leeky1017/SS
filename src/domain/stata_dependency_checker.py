from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol, Sequence

from src.domain.stata_runner import RunError
from src.utils.tenancy import DEFAULT_TENANT_ID


@dataclass(frozen=True)
class StataDependency:
    pkg: str
    source: str
    purpose: str = ""


@dataclass(frozen=True)
class StataDependencyCheckResult:
    missing: tuple[StataDependency, ...] = ()
    error: RunError | None = None


class StataDependencyChecker(Protocol):
    def check(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        run_id: str,
        dependencies: Sequence[StataDependency],
    ) -> StataDependencyCheckResult: ...

