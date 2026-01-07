from __future__ import annotations

from fastapi.testclient import TestClient

from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService, NoopJobScheduler
from src.domain.state_machine import JobStateMachine
from src.infra.job_store import JobStore
from src.infra.prometheus_metrics import PrometheusMetrics
from src.main import create_app


def test_metrics_endpoint_exists_and_exports_expected_metric_names() -> None:
    app = create_app()
    client = TestClient(app)

    response = client.get("/metrics")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")
    assert "ss_http_requests_total" in response.text
    assert "ss_http_request_duration_seconds_bucket" in response.text
    assert "ss_jobs_total" in response.text
    assert "ss_worker_inflight_jobs" in response.text


def test_job_service_create_job_records_job_created_metric(
    store: JobStore,
    state_machine: JobStateMachine,
    idempotency: JobIdempotency,
) -> None:
    metrics = PrometheusMetrics()
    svc = JobService(
        store=store,
        scheduler=NoopJobScheduler(),
        state_machine=state_machine,
        idempotency=idempotency,
        metrics=metrics,
    )

    svc.create_job(requirement="hello")

    text = metrics.render_latest().decode("utf-8")
    assert 'ss_jobs_total{event="created"} 1.0' in text

