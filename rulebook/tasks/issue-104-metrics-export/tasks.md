## 1. Implementation
- [ ] 1.1 Define a minimal Prometheus metrics set (counters/histograms/gauges)
- [ ] 1.2 Add `/metrics` endpoint (Prometheus scrape format)
- [ ] 1.3 Add request latency + error metrics instrumentation (FastAPI middleware)
- [ ] 1.4 Add job lifecycle + worker activity metrics instrumentation
- [ ] 1.5 Ensure metrics contain no sensitive data

## 2. Testing
- [ ] 2.1 Smoke test `/metrics` endpoint exists and exports expected metric names
- [ ] 2.2 Add a small unit test for job lifecycle metrics where practical

## 3. Documentation
- [ ] 3.1 Document scrape usage in the task card (deployment notes)
- [ ] 3.2 Record `ruff check .` and `pytest -q` in `openspec/_ops/task_runs/ISSUE-104.md`
