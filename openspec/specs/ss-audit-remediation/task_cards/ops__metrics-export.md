# Ops: Metrics export (Prometheus)

## Background

The audit found no metrics export, which blocks production monitoring and alerting (throughput, latency, error rates, worker activity).

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏 Metrics 导出”

## Goal

Export a production-grade metrics surface suitable for scraping (Prometheus format), covering key system health and performance indicators.

## Deployment notes

Scrape endpoints:
- API process: `GET /metrics` on the same listener as the HTTP API (default `:8000`).
- Worker process: `GET /metrics` via the built-in Prometheus server on `SS_WORKER_METRICS_PORT` (default `8001`, set `0` to disable).

Latency quantiles (PromQL examples):
- p50: `histogram_quantile(0.50, sum(rate(ss_http_request_duration_seconds_bucket[5m])) by (le, route))`
- p95: `histogram_quantile(0.95, sum(rate(ss_http_request_duration_seconds_bucket[5m])) by (le, route))`
- p99: `histogram_quantile(0.99, sum(rate(ss_http_request_duration_seconds_bucket[5m])) by (le, route))`

Data safety:
- Metrics must not include job content, prompts, or other sensitive payloads; only low-cardinality labels like route templates and status codes are allowed.

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: all non-conflicting tasks

## Acceptance checklist

- [ ] Define a minimal metrics set (counters/histograms/gauges) aligned with job lifecycle and worker activity
- [ ] Expose a scrape endpoint and document how to use it in deployment
- [ ] Ensure metrics do not leak sensitive data (job contents, prompts, etc.)
- [ ] Add a basic smoke test that the endpoint exists (where practical)
- [ ] Implementation run log records `ruff check .` and `pytest -q`

## Estimate

- 4-6h
