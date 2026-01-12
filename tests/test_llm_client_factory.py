from __future__ import annotations

from pathlib import Path

import pytest

from src.config import Config
from src.infra.exceptions import LLMConfigurationError
from src.infra.llm_client_factory import build_llm_client
from src.infra.llm_tracing import TracedLLMClient
from src.infra.openai_compatible_llm_client import OpenAICompatibleLLMClient


def _config(tmp_path: Path, **overrides: object) -> Config:
    base: dict[str, object] = {
        "jobs_dir": tmp_path / "jobs",
        "job_store_backend": "file",
        "job_store_postgres_dsn": "",
        "job_store_redis_url": "",
        "queue_dir": tmp_path / "queue",
        "queue_lease_ttl_seconds": 30,
        "do_template_library_dir": tmp_path / "do_lib",
        "stata_cmd": ("stata",),
        "log_level": "info",
        "upload_object_store_backend": "s3",
        "upload_s3_endpoint": "http://localhost:9000",
        "upload_s3_region": "us-east-1",
        "upload_s3_bucket": "bucket",
        "upload_s3_access_key_id": "key",
        "upload_s3_secret_access_key": "secret",
        "upload_presigned_url_ttl_seconds": 60,
        "upload_max_file_size_bytes": 1024,
        "upload_max_sessions_per_job": 2,
        "upload_multipart_threshold_bytes": 1024,
        "upload_multipart_min_part_size_bytes": 256,
        "upload_multipart_part_size_bytes": 256,
        "upload_multipart_max_part_size_bytes": 1024,
        "upload_multipart_max_parts": 1000,
        "upload_max_bundle_files": 50,
        "llm_timeout_seconds": 30.0,
        "llm_max_attempts": 3,
        "llm_retry_backoff_base_seconds": 1.0,
        "llm_retry_backoff_max_seconds": 30.0,
        "worker_id": "worker_1",
        "worker_idle_sleep_seconds": 0.1,
        "worker_shutdown_grace_seconds": 1.0,
        "worker_max_attempts": 3,
        "worker_retry_backoff_base_seconds": 1.0,
        "worker_retry_backoff_max_seconds": 30.0,
    }
    base.update(overrides)
    return Config(**base)


def test_build_llm_client_with_empty_provider_raises_configuration_error(tmp_path: Path) -> None:
    with pytest.raises(LLMConfigurationError):
        build_llm_client(config=_config(tmp_path))


def test_build_llm_client_with_stub_provider_raises_configuration_error(tmp_path: Path) -> None:
    with pytest.raises(LLMConfigurationError):
        build_llm_client(config=_config(tmp_path, llm_provider="stub"))


def test_build_llm_client_with_unsupported_provider_raises_configuration_error(
    tmp_path: Path,
) -> None:
    with pytest.raises(LLMConfigurationError):
        build_llm_client(config=_config(tmp_path, llm_provider="unknown"))


@pytest.mark.parametrize("provider", ["openai", "openai_compatible", "yunwu"])
def test_build_llm_client_with_openai_compatible_provider_returns_traced_client(
    tmp_path: Path, provider: str
) -> None:
    client = build_llm_client(
        config=_config(
            tmp_path,
            llm_provider=provider,
            llm_api_key="test-key",
            llm_model="test-model",
            llm_base_url="http://example.invalid/v1",
        )
    )

    assert isinstance(client, TracedLLMClient)
    assert isinstance(client._inner, OpenAICompatibleLLMClient)


def test_build_llm_client_with_missing_api_key_raises_configuration_error(tmp_path: Path) -> None:
    with pytest.raises(LLMConfigurationError):
        build_llm_client(
            config=_config(
                tmp_path,
                llm_provider="openai",
                llm_api_key="",
                llm_model="test-model",
                llm_base_url="http://example.invalid/v1",
            )
        )


def test_build_llm_client_with_empty_model_raises_configuration_error(tmp_path: Path) -> None:
    with pytest.raises(LLMConfigurationError):
        build_llm_client(
            config=_config(
                tmp_path,
                llm_provider="openai",
                llm_api_key="test-key",
                llm_model="",
                llm_base_url="http://example.invalid/v1",
            )
        )


def test_build_llm_client_with_empty_base_url_raises_configuration_error(tmp_path: Path) -> None:
    with pytest.raises(LLMConfigurationError):
        build_llm_client(
            config=_config(
                tmp_path,
                llm_provider="openai",
                llm_api_key="test-key",
                llm_model="test-model",
                llm_base_url="",
            )
        )
