from __future__ import annotations

from pathlib import Path

import pytest

from src.api import deps
from src.config import Config
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override
from tests.fakes.fake_llm_client import FakeLLMClient


def _test_config(
    *,
    jobs_dir: Path,
    queue_dir: Path,
    ss_env: str = "development",
    llm_provider: str = "stub",
    llm_api_key: str = "",
    llm_base_url: str = "https://yunwu.ai/v1",
    llm_model: str = "claude-opus-4-5-20251101",
    stata_cmd: tuple[str, ...] = tuple(),
    upload_object_store_backend: str = "s3",
    upload_s3_bucket: str = "",
    upload_s3_access_key_id: str = "",
    upload_s3_secret_access_key: str = "",
) -> Config:
    return Config(
        jobs_dir=jobs_dir,
        job_store_backend="file",
        job_store_postgres_dsn="",
        job_store_redis_url="",
        queue_dir=queue_dir,
        queue_lease_ttl_seconds=60,
        do_template_library_dir=jobs_dir,
        stata_cmd=stata_cmd,
        log_level="INFO",
        upload_object_store_backend=upload_object_store_backend,
        upload_s3_endpoint="",
        upload_s3_region="",
        upload_s3_bucket=upload_s3_bucket,
        upload_s3_access_key_id=upload_s3_access_key_id,
        upload_s3_secret_access_key=upload_s3_secret_access_key,
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
        ss_env=ss_env,
        llm_provider=llm_provider,
        llm_api_key=llm_api_key,
        llm_base_url=llm_base_url,
        llm_model=llm_model,
    )


@pytest.mark.anyio
async def test_health_live_always_ok_returns_200():
    app = create_app()

    async with asgi_client(app=app) as client:
        response = await client.get("/health/live")

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["checks"]["process"]["ok"] is True


@pytest.mark.anyio
async def test_health_ready_with_writable_dirs_returns_200(tmp_path: Path):
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"

    app = create_app()
    app.dependency_overrides[deps.get_config] = async_override(
        _test_config(jobs_dir=jobs_dir, queue_dir=queue_dir)
    )
    app.dependency_overrides[deps.get_llm_client] = async_override(FakeLLMClient())

    async with asgi_client(app=app) as client:
        response = await client.get("/health/ready")

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["checks"]["jobs_dir"]["ok"] is True
    assert payload["checks"]["queue_dir"]["ok"] is True


@pytest.mark.anyio
async def test_health_ready_with_unwritable_jobs_dir_returns_503(tmp_path: Path):
    jobs_dir = tmp_path / "jobs_file"
    jobs_dir.write_text("not a directory", encoding="utf-8")
    queue_dir = tmp_path / "queue"

    app = create_app()
    app.dependency_overrides[deps.get_config] = async_override(
        _test_config(jobs_dir=jobs_dir, queue_dir=queue_dir)
    )
    app.dependency_overrides[deps.get_llm_client] = async_override(FakeLLMClient())

    async with asgi_client(app=app) as client:
        response = await client.get("/health/ready")

    assert response.status_code == 503
    payload = response.json()
    assert payload["status"] == "unhealthy"
    assert payload["checks"]["jobs_dir"]["ok"] is False


@pytest.mark.anyio
async def test_health_ready_in_production_with_stub_llm_returns_503_and_logs_reason(
    tmp_path: Path,
    caplog: pytest.LogCaptureFixture,
):
    caplog.set_level("WARNING")
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"

    app = create_app()
    app.dependency_overrides[deps.get_config] = async_override(
        _test_config(
            jobs_dir=jobs_dir,
            queue_dir=queue_dir,
            ss_env="production",
            llm_provider="stub",
            stata_cmd=("stata",),
            upload_object_store_backend="s3",
            upload_s3_bucket="bucket",
            upload_s3_access_key_id="akid",
            upload_s3_secret_access_key="secret",
        )
    )
    app.dependency_overrides[deps.get_llm_client] = async_override(FakeLLMClient())

    async with asgi_client(app=app) as client:
        response = await client.get("/health/ready")

    assert response.status_code == 503
    payload = response.json()
    assert payload["checks"]["prod_llm"]["ok"] is False
    assert "SS_PRODUCTION_GATE_DEPENDENCY_MISSING" in caplog.text


@pytest.mark.anyio
async def test_health_ready_in_production_when_upload_store_config_missing_returns_503(
    tmp_path: Path,
    caplog: pytest.LogCaptureFixture,
):
    caplog.set_level("WARNING")
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"

    app = create_app()
    app.dependency_overrides[deps.get_config] = async_override(
        _test_config(
            jobs_dir=jobs_dir,
            queue_dir=queue_dir,
            ss_env="production",
            llm_provider="yunwu",
            llm_api_key="test-key",
            llm_base_url="https://example.invalid/v1",
            llm_model="test-model",
            stata_cmd=("stata",),
            upload_object_store_backend="s3",
            upload_s3_bucket="",
            upload_s3_access_key_id="",
            upload_s3_secret_access_key="",
        )
    )
    app.dependency_overrides[deps.get_llm_client] = async_override(StubLLMClient())

    async with asgi_client(app=app) as client:
        response = await client.get("/health/ready")

    assert response.status_code == 503
    payload = response.json()
    assert payload["checks"]["prod_upload_object_store"]["ok"] is False
    assert "SS_PRODUCTION_GATE_DEPENDENCY_MISSING" in caplog.text


@pytest.mark.anyio
async def test_health_ready_in_production_with_real_config_returns_200(tmp_path: Path):
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"

    app = create_app()
    app.dependency_overrides[deps.get_config] = async_override(
        _test_config(
            jobs_dir=jobs_dir,
            queue_dir=queue_dir,
            ss_env="production",
            llm_provider="yunwu",
            llm_api_key="test-key",
            llm_base_url="https://example.invalid/v1",
            llm_model="test-model",
            stata_cmd=("stata",),
            upload_object_store_backend="s3",
            upload_s3_bucket="bucket",
            upload_s3_access_key_id="akid",
            upload_s3_secret_access_key="secret",
        )
    )
    app.dependency_overrides[deps.get_llm_client] = async_override(FakeLLMClient())

    async with asgi_client(app=app) as client:
        response = await client.get("/health/ready")

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["checks"]["prod_llm"]["ok"] is True
    assert payload["checks"]["prod_runner"]["ok"] is True
    assert payload["checks"]["prod_upload_object_store"]["ok"] is True
