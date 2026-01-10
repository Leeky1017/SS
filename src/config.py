from __future__ import annotations

import os
import shlex
from dataclasses import dataclass, field
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
    upload_object_store_backend: str
    upload_s3_endpoint: str
    upload_s3_region: str
    upload_s3_bucket: str
    upload_s3_access_key_id: str
    upload_s3_secret_access_key: str
    upload_presigned_url_ttl_seconds: int
    upload_max_file_size_bytes: int
    upload_max_sessions_per_job: int
    upload_multipart_threshold_bytes: int
    upload_multipart_min_part_size_bytes: int
    upload_multipart_part_size_bytes: int
    upload_multipart_max_part_size_bytes: int
    upload_multipart_max_parts: int
    upload_max_bundle_files: int
    ss_env: str = field(default="development", kw_only=True)
    llm_provider: str = field(default="stub", kw_only=True)
    llm_base_url: str = field(default="https://yunwu.ai/v1", kw_only=True)
    llm_api_key: str = field(default="", kw_only=True)
    llm_model: str = field(default="claude-opus-4-5-20251101", kw_only=True)
    llm_temperature: float | None = field(default=None, kw_only=True)
    llm_seed: str | None = field(default=None, kw_only=True)
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
    worker_metrics_port: int = 8001
    v1_enable_legacy_post_jobs: bool = field(default=True, kw_only=True)
    tracing_enabled: bool = field(default=False, kw_only=True)
    tracing_service_name: str = field(default="ss", kw_only=True)
    tracing_exporter: str = field(default="otlp", kw_only=True)
    tracing_otlp_endpoint: str = field(default="http://localhost:4318/v1/traces", kw_only=True)
    tracing_sample_ratio: float = field(default=1.0, kw_only=True)

    def is_production(self) -> bool:
        return self.ss_env in {"production", "prod"}


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


def _bool_value(raw: str, *, default: bool) -> bool:
    value = str(raw).strip().lower()
    if value in {"1", "true", "yes", "y", "on"}:
        return True
    if value in {"0", "false", "no", "n", "off"}:
        return False
    return default


def _clamped_ratio(raw: str, *, default: float) -> float:
    ratio = _float_value(raw, default=default)
    if ratio < 0.0:
        return 0.0
    if ratio > 1.0:
        return 1.0
    return ratio


def _clamped_int(
    raw: str,
    *,
    default: int,
    min_value: int | None = None,
    max_value: int | None = None,
) -> int:
    value = _int_value(raw, default=default)
    if min_value is not None and value < min_value:
        return min_value
    if max_value is not None and value > max_value:
        return max_value
    return value


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
    ss_env = str(e.get("SS_ENV", "development")).strip().lower()
    ss_env = "development" if ss_env == "" else ss_env
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
    upload_object_store_backend = (
        str(e.get("SS_UPLOAD_OBJECT_STORE_BACKEND", "s3")).strip().lower()
    )
    upload_s3_endpoint = str(e.get("SS_UPLOAD_S3_ENDPOINT", "")).strip()
    upload_s3_region = str(e.get("SS_UPLOAD_S3_REGION", "")).strip()
    upload_s3_bucket = str(e.get("SS_UPLOAD_S3_BUCKET", "")).strip()
    upload_s3_access_key_id = str(e.get("SS_UPLOAD_S3_ACCESS_KEY_ID", "")).strip()
    upload_s3_secret_access_key = str(e.get("SS_UPLOAD_S3_SECRET_ACCESS_KEY", "")).strip()
    upload_presigned_url_ttl_seconds = _clamped_int(
        str(e.get("SS_UPLOAD_PRESIGNED_URL_TTL_SECONDS", "900")),
        default=900,
        min_value=1,
        max_value=900,
    )
    upload_max_file_size_bytes = _clamped_int(
        str(e.get("SS_UPLOAD_MAX_FILE_SIZE_BYTES", str(5 * 1024 * 1024 * 1024))),
        default=5 * 1024 * 1024 * 1024,
        min_value=1,
    )
    upload_max_sessions_per_job = _clamped_int(
        str(e.get("SS_UPLOAD_MAX_SESSIONS_PER_JOB", "64")),
        default=64,
        min_value=1,
    )
    upload_multipart_threshold_bytes = _clamped_int(
        str(e.get("SS_UPLOAD_MULTIPART_THRESHOLD_BYTES", str(64 * 1024 * 1024))),
        default=64 * 1024 * 1024,
        min_value=1,
    )
    upload_multipart_min_part_size_bytes = _clamped_int(
        str(e.get("SS_UPLOAD_MULTIPART_MIN_PART_SIZE_BYTES", str(5 * 1024 * 1024))),
        default=5 * 1024 * 1024,
        min_value=1,
    )
    upload_multipart_max_part_size_bytes = _clamped_int(
        str(e.get("SS_UPLOAD_MULTIPART_MAX_PART_SIZE_BYTES", str(64 * 1024 * 1024))),
        default=64 * 1024 * 1024,
        min_value=upload_multipart_min_part_size_bytes,
    )
    upload_multipart_part_size_bytes = _clamped_int(
        str(e.get("SS_UPLOAD_MULTIPART_PART_SIZE_BYTES", str(8 * 1024 * 1024))),
        default=8 * 1024 * 1024,
        min_value=upload_multipart_min_part_size_bytes,
        max_value=upload_multipart_max_part_size_bytes,
    )
    upload_multipart_max_parts = _clamped_int(
        str(e.get("SS_UPLOAD_MULTIPART_MAX_PARTS", "10000")),
        default=10000,
        min_value=1,
        max_value=10000,
    )
    upload_max_bundle_files = _clamped_int(
        str(e.get("SS_UPLOAD_MAX_BUNDLE_FILES", "64")),
        default=64,
        min_value=1,
    )
    llm_provider = str(e.get("SS_LLM_PROVIDER", "stub")).strip().lower()
    llm_base_url = str(e.get("SS_LLM_BASE_URL", "https://yunwu.ai/v1")).strip()
    llm_api_key = str(e.get("SS_LLM_API_KEY", "")).strip()
    llm_model = str(e.get("SS_LLM_MODEL", "claude-opus-4-5-20251101")).strip()
    if llm_model == "claude-opus-4-5":
        llm_model = "claude-opus-4-5-20251101"
    llm_temperature_raw = str(e.get("SS_LLM_TEMPERATURE", "")).strip()
    llm_temperature = None
    if llm_temperature_raw != "":
        llm_temperature = _float_value(llm_temperature_raw, default=0.0)
    llm_seed_raw = str(e.get("SS_LLM_SEED", "")).strip()
    llm_seed = None if llm_seed_raw == "" else llm_seed_raw
    tracing_enabled = _bool_value(str(e.get("SS_TRACING_ENABLED", "0")), default=False)
    tracing_service_name = str(e.get("SS_TRACING_SERVICE_NAME", "ss")).strip() or "ss"
    tracing_exporter = str(e.get("SS_TRACING_EXPORTER", "otlp")).strip().lower()
    if tracing_exporter not in {"otlp", "console"}:
        tracing_exporter = "otlp"
    tracing_otlp_endpoint = str(
        e.get("SS_TRACING_OTLP_ENDPOINT", "http://localhost:4318/v1/traces")
    ).strip()
    tracing_sample_ratio = _clamped_ratio(
        str(e.get("SS_TRACING_SAMPLE_RATIO", "1.0")),
        default=1.0,
    )
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
    v1_enable_legacy_post_jobs = _bool_value(
        str(e.get("SS_V1_ENABLE_LEGACY_POST_JOBS", "1")),
        default=True,
    )
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
        upload_object_store_backend=upload_object_store_backend,
        upload_s3_endpoint=upload_s3_endpoint,
        upload_s3_region=upload_s3_region,
        upload_s3_bucket=upload_s3_bucket,
        upload_s3_access_key_id=upload_s3_access_key_id,
        upload_s3_secret_access_key=upload_s3_secret_access_key,
        upload_presigned_url_ttl_seconds=upload_presigned_url_ttl_seconds,
        upload_max_file_size_bytes=upload_max_file_size_bytes,
        upload_max_sessions_per_job=upload_max_sessions_per_job,
        upload_multipart_threshold_bytes=upload_multipart_threshold_bytes,
        upload_multipart_min_part_size_bytes=upload_multipart_min_part_size_bytes,
        upload_multipart_part_size_bytes=upload_multipart_part_size_bytes,
        upload_multipart_max_part_size_bytes=upload_multipart_max_part_size_bytes,
        upload_multipart_max_parts=upload_multipart_max_parts,
        upload_max_bundle_files=upload_max_bundle_files,
        ss_env=ss_env,
        llm_provider=llm_provider,
        llm_base_url=llm_base_url,
        llm_api_key=llm_api_key,
        llm_model=llm_model,
        llm_temperature=llm_temperature,
        llm_seed=llm_seed,
        tracing_enabled=tracing_enabled,
        tracing_service_name=tracing_service_name,
        tracing_exporter=tracing_exporter,
        tracing_otlp_endpoint=tracing_otlp_endpoint,
        tracing_sample_ratio=tracing_sample_ratio,
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
        v1_enable_legacy_post_jobs=v1_enable_legacy_post_jobs,
    )
