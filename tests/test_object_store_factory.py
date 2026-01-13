from __future__ import annotations

from pathlib import Path

import pytest

from src.config import Config
from src.infra.object_store_exceptions import ObjectStoreConfigurationError
from src.infra.object_store_factory import build_object_store
from src.infra.s3_object_store import S3ObjectStore


def _test_config(*, upload_object_store_backend: str) -> Config:
    return Config(
        jobs_dir=Path("/tmp/ss-tests/jobs"),
        job_store_backend="file",
        job_store_postgres_dsn="",
        job_store_redis_url="",
        queue_dir=Path("/tmp/ss-tests/queue"),
        queue_lease_ttl_seconds=60,
        admin_data_dir=Path("/tmp/ss-tests/jobs") / "_admin",
        admin_username="admin",
        admin_password="admin",
        do_template_library_dir=Path("/tmp/ss-tests/assets"),
        stata_cmd=tuple(),
        log_level="INFO",
        upload_object_store_backend=upload_object_store_backend,
        upload_s3_endpoint="",
        upload_s3_region="",
        upload_s3_bucket="bucket",
        upload_s3_access_key_id="akid",
        upload_s3_secret_access_key="secret",
        upload_presigned_url_ttl_seconds=900,
        upload_max_file_size_bytes=5 * 1024 * 1024 * 1024,
        upload_max_sessions_per_job=64,
        upload_multipart_threshold_bytes=64 * 1024 * 1024,
        upload_multipart_min_part_size_bytes=5 * 1024 * 1024,
        upload_multipart_part_size_bytes=8 * 1024 * 1024,
        upload_multipart_max_part_size_bytes=64 * 1024 * 1024,
        upload_multipart_max_parts=10000,
        upload_max_bundle_files=64,
        llm_timeout_seconds=30.0,
        llm_max_attempts=3,
        llm_retry_backoff_base_seconds=1.0,
        llm_retry_backoff_max_seconds=30.0,
        worker_id="worker-test",
        worker_idle_sleep_seconds=1.0,
        worker_shutdown_grace_seconds=30.0,
        worker_max_attempts=3,
        worker_retry_backoff_base_seconds=1.0,
        worker_retry_backoff_max_seconds=30.0,
    )


def test_build_object_store_with_fake_backend_raises_configuration_error() -> None:
    config = _test_config(upload_object_store_backend="fake")

    with pytest.raises(ObjectStoreConfigurationError) as excinfo:
        build_object_store(config=config)

    assert excinfo.value.error_code == "OBJECT_STORE_CONFIG_INVALID"
    assert "unsupported SS_UPLOAD_OBJECT_STORE_BACKEND" in excinfo.value.message


def test_build_object_store_with_s3_backend_returns_s3_store() -> None:
    config = _test_config(upload_object_store_backend="s3")

    store = build_object_store(config=config)

    assert isinstance(store, S3ObjectStore)
