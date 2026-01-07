from __future__ import annotations

import logging
import tempfile
from dataclasses import dataclass
from pathlib import Path

from src.domain.llm_client import LLMClient

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class DependencyCheck:
    ok: bool
    detail: str | None = None


@dataclass(frozen=True)
class ReadinessReport:
    ok: bool
    checks: dict[str, DependencyCheck]


def _check_dir_writable(*, name: str, path: Path) -> DependencyCheck:
    try:
        path.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=str(path), delete=True) as f:
            f.write("ok")
    except OSError as e:
        logger.warning(
            "SS_HEALTH_DEPENDENCY_UNAVAILABLE",
            extra={"dependency": name, "path": str(path), "error_type": type(e).__name__},
        )
        return DependencyCheck(ok=False, detail=f"{type(e).__name__}: {e}")
    if not path.is_dir():
        logger.warning(
            "SS_HEALTH_DEPENDENCY_UNAVAILABLE",
            extra={"dependency": name, "path": str(path), "reason": "not_dir"},
        )
        return DependencyCheck(ok=False, detail="not_a_directory")
    return DependencyCheck(ok=True)


class HealthService:
    def __init__(self, *, jobs_dir: Path, queue_dir: Path, llm: LLMClient):
        self._jobs_dir = Path(jobs_dir)
        self._queue_dir = Path(queue_dir)
        self._llm = llm

    def readiness(self, *, shutting_down: bool) -> ReadinessReport:
        checks: dict[str, DependencyCheck] = {
            "shutting_down": DependencyCheck(
                ok=not shutting_down,
                detail=None if not shutting_down else "shutdown_in_progress",
            ),
            "jobs_dir": _check_dir_writable(name="jobs_dir", path=self._jobs_dir),
            "queue_dir": _check_dir_writable(name="queue_dir", path=self._queue_dir),
            "llm": DependencyCheck(ok=True, detail=type(self._llm).__name__),
        }
        ok = all(check.ok for check in checks.values())
        return ReadinessReport(ok=ok, checks=checks)

