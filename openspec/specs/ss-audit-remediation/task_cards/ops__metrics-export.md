# Ops: Metrics export (Prometheus)

## Background

The audit found no metrics export, which blocks production monitoring and alerting (throughput, latency, error rates, worker activity).

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏 Metrics 导出”

## Goal

Export a production-grade metrics surface suitable for scraping (Prometheus format), covering key system health and performance indicators.

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

