from __future__ import annotations

import os
import shlex
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping


@dataclass(frozen=True)
class Config:
    jobs_dir: Path
    job_store_backend: str
    job_store_postgres_dsn: str
    job_store_redis_url: str
    queue_dir: Path
    queue_lease_ttl_seconds: int
    do_template_library_dir: Path
    stata_cmd: tuple[str, ...]
    log_level: str
    llm_timeout_seconds: float
    llm_max_attempts: int
    llm_retry_backoff_base_seconds: float
    llm_retry_backoff_max_seconds: float
    worker_id: str
    worker_idle_sleep_seconds: float
    worker_shutdown_grace_seconds: float
    worker_max_attempts: int
    worker_retry_backoff_base_seconds: float
    worker_retry_backoff_max_seconds: float
    worker_metrics_port: int


def _int_value(raw: str, *, default: int) -> int:
    try:
        return int(raw)
    except (TypeError, ValueError):
        return default


def _float_value(raw: str, *, default: float) -> float:
    try:
        return float(raw)
    except (TypeError, ValueError):
        return default


def _load_llm_settings(*, env: Mapping[str, str]) -> tuple[float, int, float, float]:
    timeout_seconds = _float_value(str(env.get("SS_LLM_TIMEOUT_SECONDS", "30.0")), default=30.0)
    max_attempts = _int_value(str(env.get("SS_LLM_MAX_ATTEMPTS", "3")), default=3)
    backoff_base_seconds = _float_value(
        str(env.get("SS_LLM_RETRY_BACKOFF_BASE_SECONDS", "1.0")),
        default=1.0,
    )
    backoff_max_seconds = _float_value(
        str(env.get("SS_LLM_RETRY_BACKOFF_MAX_SECONDS", "30.0")),
        default=30.0,
    )
    return timeout_seconds, max_attempts, backoff_base_seconds, backoff_max_seconds


def load_config(env: Mapping[str, str] | None = None) -> Config:
    """Load config from environment variables with explicit defaults."""
    e = os.environ if env is None else env
    jobs_dir = Path(str(e.get("SS_JOBS_DIR", "./jobs"))).expanduser()
    job_store_backend = str(e.get("SS_JOB_STORE_BACKEND", "file")).strip().lower()
    job_store_postgres_dsn = str(e.get("SS_JOB_STORE_POSTGRES_DSN", "")).strip()
    job_store_redis_url = str(e.get("SS_JOB_STORE_REDIS_URL", "")).strip()
    queue_dir = Path(str(e.get("SS_QUEUE_DIR", "./queue"))).expanduser()
    queue_lease_ttl_seconds = _int_value(str(e.get("SS_QUEUE_LEASE_TTL_SECONDS", "60")), default=60)
    do_template_library_dir = Path(
        str(e.get("SS_DO_TEMPLATE_LIBRARY_DIR", "./assets/stata_do_library"))
    ).expanduser()
    stata_cmd_raw = str(e.get("SS_STATA_CMD", "")).strip()
    stata_cmd = tuple(shlex.split(stata_cmd_raw)) if stata_cmd_raw != "" else tuple()
    log_level = str(e.get("SS_LOG_LEVEL", "INFO")).strip().upper()
    llm_timeout_seconds, llm_max_attempts, llm_backoff_base, llm_backoff_max = _load_llm_settings(
        env=e
    )
    worker_id = str(e.get("SS_WORKER_ID", "worker-local")).strip()
    worker_idle_sleep_seconds = _float_value(
        str(e.get("SS_WORKER_IDLE_SLEEP_SECONDS", "1.0")),
        default=1.0,
    )
    worker_shutdown_grace_seconds = _float_value(
        str(e.get("SS_WORKER_SHUTDOWN_GRACE_SECONDS", "30.0")),
        default=30.0,
    )
    worker_max_attempts = _int_value(str(e.get("SS_WORKER_MAX_ATTEMPTS", "3")), default=3)
    worker_retry_backoff_base_seconds = _float_value(
        str(e.get("SS_WORKER_RETRY_BACKOFF_BASE_SECONDS", "1.0")),
        default=1.0,
    )
    worker_retry_backoff_max_seconds = _float_value(
        str(e.get("SS_WORKER_RETRY_BACKOFF_MAX_SECONDS", "30.0")),
        default=30.0,
    )
    worker_metrics_port = _int_value(str(e.get("SS_WORKER_METRICS_PORT", "8001")), default=8001)
    return Config(
        jobs_dir=jobs_dir,
        job_store_backend=job_store_backend,
        job_store_postgres_dsn=job_store_postgres_dsn,
        job_store_redis_url=job_store_redis_url,
        queue_dir=queue_dir,
        queue_lease_ttl_seconds=queue_lease_ttl_seconds,
        do_template_library_dir=do_template_library_dir,
        stata_cmd=stata_cmd,
        log_level=log_level,
        llm_timeout_seconds=llm_timeout_seconds,
        llm_max_attempts=llm_max_attempts,
        llm_retry_backoff_base_seconds=llm_backoff_base,
        llm_retry_backoff_max_seconds=llm_backoff_max,
        worker_id=worker_id,
        worker_idle_sleep_seconds=worker_idle_sleep_seconds,
        worker_shutdown_grace_seconds=worker_shutdown_grace_seconds,
        worker_max_attempts=worker_max_attempts,
        worker_retry_backoff_base_seconds=worker_retry_backoff_base_seconds,
        worker_retry_backoff_max_seconds=worker_retry_backoff_max_seconds,
        worker_metrics_port=worker_metrics_port,
    )
