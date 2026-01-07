## 1. Spec-first
- [x] 1.1 Update observability spec to include trace context + required log fields
- [x] 1.2 Define propagation strategy (API → queue → worker) and exporter config knobs

## 2. Implementation
- [x] 2.1 Add tracing configuration and initialization in API + worker
- [x] 2.2 Persist `trace_id` on job creation and propagate trace context via queue records
- [x] 2.3 Instrument spans: job creation, enqueue, queue claim, job execution, LLM call boundary
- [x] 2.4 Ensure no sensitive data is attached to spans/log fields

## 3. Tests
- [x] 3.1 Add unit tests for queue trace propagation and log fields

## 4. Evidence
- [x] 4.1 Record run evidence: `ruff check .`, `pytest -q`, `openspec validate --specs --strict --no-interactive`
