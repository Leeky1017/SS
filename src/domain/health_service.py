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


@dataclass(frozen=True)
class ProductionGateConfig:
    is_production: bool
    ss_env: str
    llm_provider: str
    llm_api_key: str
    llm_base_url: str
    llm_model: str
    stata_cmd: tuple[str, ...]
    upload_object_store_backend: str
    upload_s3_bucket: str
    upload_s3_access_key_id: str
    upload_s3_secret_access_key: str


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


def _skipped_non_production() -> DependencyCheck:
    return DependencyCheck(ok=True, detail="skipped_non_production")


def _llm_missing_env_vars(*, gate: ProductionGateConfig) -> list[str]:
    missing: list[str] = []
    if gate.llm_api_key.strip() == "":
        missing.append("SS_LLM_API_KEY")
    if gate.llm_model.strip() == "":
        missing.append("SS_LLM_MODEL")
    if gate.llm_base_url.strip() == "":
        missing.append("SS_LLM_BASE_URL")
    return missing


def _check_llm_production_gate(*, gate: ProductionGateConfig) -> DependencyCheck:
    if not gate.is_production:
        return _skipped_non_production()

    provider = gate.llm_provider.strip().lower()
    if provider in {"", "stub"}:
        logger.warning(
            "SS_PRODUCTION_GATE_DEPENDENCY_MISSING",
            extra={"dependency": "llm", "ss_env": gate.ss_env, "provider": provider or None},
        )
        return DependencyCheck(ok=False, detail="stub_or_empty_provider")

    if provider in {"openai", "openai_compatible", "yunwu"}:
        missing = _llm_missing_env_vars(gate=gate)
        if missing:
            logger.warning(
                "SS_PRODUCTION_GATE_DEPENDENCY_MISSING",
                extra={
                    "dependency": "llm",
                    "ss_env": gate.ss_env,
                    "provider": provider,
                    "missing": missing,
                },
            )
            return DependencyCheck(ok=False, detail=f"missing:{','.join(missing)}")
        return DependencyCheck(ok=True, detail=provider)

    logger.warning(
        "SS_PRODUCTION_GATE_DEPENDENCY_UNSUPPORTED",
        extra={"dependency": "llm", "ss_env": gate.ss_env, "provider": provider},
    )
    return DependencyCheck(ok=False, detail=f"unsupported_provider:{provider}")


def _check_runner_production_gate(*, gate: ProductionGateConfig) -> DependencyCheck:
    if not gate.is_production:
        return _skipped_non_production()
    if not gate.stata_cmd:
        logger.warning(
            "SS_PRODUCTION_GATE_DEPENDENCY_MISSING",
            extra={"dependency": "runner", "ss_env": gate.ss_env, "missing": ["SS_STATA_CMD"]},
        )
        return DependencyCheck(ok=False, detail="SS_STATA_CMD_not_set")
    return DependencyCheck(ok=True, detail="configured")


def _s3_missing_env_vars(*, gate: ProductionGateConfig) -> list[str]:
    missing: list[str] = []
    if gate.upload_s3_bucket.strip() == "":
        missing.append("SS_UPLOAD_S3_BUCKET")
    if gate.upload_s3_access_key_id.strip() == "":
        missing.append("SS_UPLOAD_S3_ACCESS_KEY_ID")
    if gate.upload_s3_secret_access_key.strip() == "":
        missing.append("SS_UPLOAD_S3_SECRET_ACCESS_KEY")
    return missing


def _check_upload_store_production_gate(*, gate: ProductionGateConfig) -> DependencyCheck:
    if not gate.is_production:
        return _skipped_non_production()

    backend = gate.upload_object_store_backend.strip().lower()
    if backend in {"", "fake"}:
        logger.warning(
            "SS_PRODUCTION_GATE_DEPENDENCY_MISSING",
            extra={"dependency": "upload_object_store", "ss_env": gate.ss_env, "backend": backend},
        )
        return DependencyCheck(ok=False, detail="fake_or_empty_backend")

    if backend == "s3":
        missing = _s3_missing_env_vars(gate=gate)
        if missing:
            logger.warning(
                "SS_PRODUCTION_GATE_DEPENDENCY_MISSING",
                extra={
                    "dependency": "upload_object_store",
                    "ss_env": gate.ss_env,
                    "backend": backend,
                    "missing": missing,
                },
            )
            return DependencyCheck(ok=False, detail=f"missing:{','.join(missing)}")
        return DependencyCheck(ok=True, detail="s3")

    logger.warning(
        "SS_PRODUCTION_GATE_DEPENDENCY_UNSUPPORTED",
        extra={"dependency": "upload_object_store", "ss_env": gate.ss_env, "backend": backend},
    )
    return DependencyCheck(ok=False, detail=f"unsupported_backend:{backend}")


class HealthService:
    def __init__(
        self,
        *,
        jobs_dir: Path,
        queue_dir: Path,
        llm: LLMClient,
        production_gate: ProductionGateConfig,
    ):
        self._jobs_dir = Path(jobs_dir)
        self._queue_dir = Path(queue_dir)
        self._llm = llm
        self._production_gate = production_gate

    def readiness(self, *, shutting_down: bool) -> ReadinessReport:
        checks: dict[str, DependencyCheck] = {
            "shutting_down": DependencyCheck(
                ok=not shutting_down,
                detail=None if not shutting_down else "shutdown_in_progress",
            ),
            "jobs_dir": _check_dir_writable(name="jobs_dir", path=self._jobs_dir),
            "queue_dir": _check_dir_writable(name="queue_dir", path=self._queue_dir),
            "llm": DependencyCheck(
                ok=True,
                detail=f"{self._production_gate.llm_provider}:{type(self._llm).__name__}",
            ),
            "production_mode": DependencyCheck(
                ok=True,
                detail="production"
                if self._production_gate.is_production
                else (self._production_gate.ss_env.strip() or "non_production"),
            ),
            "prod_llm": _check_llm_production_gate(gate=self._production_gate),
            "prod_runner": _check_runner_production_gate(gate=self._production_gate),
            "prod_upload_object_store": _check_upload_store_production_gate(
                gate=self._production_gate
            ),
        }
        ok = all(check.ok for check in checks.values())
        return ReadinessReport(ok=ok, checks=checks)
