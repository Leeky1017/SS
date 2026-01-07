# Phase 2: LLM timeout + retry policy

## Background

The audit flagged that LLM calls have no explicit timeout and retry policy, which can lead to indefinite hangs or fragile failures under transient network/provider instability.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “LLM 调用的超时与重试策略不明确”

## Goal

Define and implement an explicit, configurable LLM timeout and retry/backoff policy, with structured logs for timeouts and final failures.

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: API versioning, distributed storage evaluation

## Acceptance checklist

- [ ] Timeout, retry count, and backoff policy are defined and configurable via `src/config.py`
- [ ] LLM calls are bounded by timeout and do not hang indefinitely
- [ ] Retries emit structured logs containing `job_id`, `attempt`, and `timeout_seconds`
- [ ] Tests cover timeout and retry behavior using a fake LLM client (no network dependency)
- [ ] Implementation run log records `ruff check .`, `pytest -q`, and `openspec validate --specs --strict --no-interactive`

## Estimate

- 4-6h

