from __future__ import annotations

from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
    start_http_server,
)

DEFAULT_DURATION_BUCKETS: tuple[float, ...] = (
    0.005,
    0.01,
    0.025,
    0.05,
    0.1,
    0.25,
    0.5,
    1.0,
    2.5,
    5.0,
    10.0,
)

class PrometheusMetrics:
    def __init__(self) -> None:
        self._registry = CollectorRegistry()

        self._jobs_total = Counter(
            "ss_jobs_total",
            "SS job lifecycle events",
            labelnames=("event",),
            registry=self._registry,
        )
        self._worker_inflight_jobs = Gauge(
            "ss_worker_inflight_jobs",
            "In-flight jobs being processed by the worker",
            labelnames=("worker_id",),
            registry=self._registry,
        )
        self._worker_up = Gauge(
            "ss_worker_up",
            "Worker process up (1) / down (0)",
            labelnames=("worker_id",),
            registry=self._registry,
        )
        self._http_requests_total = Counter(
            "ss_http_requests_total",
            "HTTP request count",
            labelnames=("method", "route", "status_code"),
            registry=self._registry,
        )
        self._http_request_duration_seconds = Histogram(
            "ss_http_request_duration_seconds",
            "HTTP request latency in seconds",
            labelnames=("method", "route", "status_code"),
            buckets=DEFAULT_DURATION_BUCKETS,
            registry=self._registry,
        )

    @property
    def content_type_latest(self) -> str:
        return CONTENT_TYPE_LATEST

    def render_latest(self) -> bytes:
        return generate_latest(self._registry)

    def start_http_server(self, *, port: int, addr: str = "0.0.0.0") -> None:
        start_http_server(port, addr=addr, registry=self._registry)

    def record_job_created(self) -> None:
        self._jobs_total.labels(event="created").inc()

    def record_job_finished(self, *, status: str) -> None:
        if status not in {"succeeded", "failed"}:
            return
        self._jobs_total.labels(event=status).inc()

    def worker_inflight_inc(self, *, worker_id: str) -> None:
        self._worker_inflight_jobs.labels(worker_id=worker_id).inc()

    def worker_inflight_dec(self, *, worker_id: str) -> None:
        self._worker_inflight_jobs.labels(worker_id=worker_id).dec()

    def set_worker_up(self, *, worker_id: str, up: bool) -> None:
        self._worker_up.labels(worker_id=worker_id).set(1.0 if up else 0.0)

    def observe_http_request(
        self,
        *,
        method: str,
        route: str,
        status_code: int,
        duration_seconds: float,
    ) -> None:
        status = str(status_code)
        self._http_requests_total.labels(method=method, route=route, status_code=status).inc()
        self._http_request_duration_seconds.labels(
            method=method, route=route, status_code=status
        ).observe(duration_seconds)
