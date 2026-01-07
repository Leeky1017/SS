from __future__ import annotations

from pathlib import Path

from fastapi.testclient import TestClient

from src.api import deps
from src.config import Config
from src.domain.llm_client import StubLLMClient
from src.main import create_app


def _test_config(*, jobs_dir: Path, queue_dir: Path) -> Config:
    return Config(
        jobs_dir=jobs_dir,
        job_store_backend="file",
        job_store_postgres_dsn="",
        job_store_redis_url="",
        queue_dir=queue_dir,
        queue_lease_ttl_seconds=60,
        do_template_library_dir=jobs_dir,
        stata_cmd=tuple(),
        log_level="INFO",
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


def test_health_live_always_ok_returns_200():
    app = create_app()
    client = TestClient(app)

    response = client.get("/health/live")

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["checks"]["process"]["ok"] is True


def test_health_ready_with_writable_dirs_returns_200(tmp_path: Path):
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"

    app = create_app()
    app.dependency_overrides[deps.get_config] = lambda: _test_config(
        jobs_dir=jobs_dir, queue_dir=queue_dir
    )
    app.dependency_overrides[deps.get_llm_client] = lambda: StubLLMClient()
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["checks"]["jobs_dir"]["ok"] is True
    assert payload["checks"]["queue_dir"]["ok"] is True


def test_health_ready_with_unwritable_jobs_dir_returns_503(tmp_path: Path):
    jobs_dir = tmp_path / "jobs_file"
    jobs_dir.write_text("not a directory", encoding="utf-8")
    queue_dir = tmp_path / "queue"

    app = create_app()
    app.dependency_overrides[deps.get_config] = lambda: _test_config(
        jobs_dir=jobs_dir, queue_dir=queue_dir
    )
    app.dependency_overrides[deps.get_llm_client] = lambda: StubLLMClient()
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 503
    payload = response.json()
    assert payload["status"] == "unhealthy"
    assert payload["checks"]["jobs_dir"]["ok"] is False
