from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from src.domain.models import ArtifactRef
from src.utils.tenancy import DEFAULT_TENANT_ID


@dataclass(frozen=True)
class RunError:
    error_code: str
    message: str


@dataclass(frozen=True)
class RunResult:
    job_id: str
    run_id: str
    ok: bool
    exit_code: int | None
    timed_out: bool
    artifacts: tuple[ArtifactRef, ...]
    error: RunError | None = None


class StataRunner(Protocol):
    def run(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
        inputs_dir_rel: str | None = None,
    ) -> RunResult: ...
