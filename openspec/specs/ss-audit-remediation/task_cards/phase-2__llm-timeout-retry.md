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

- [x] Timeout, retry count, and backoff policy are defined and configurable via `src/config.py`
- [x] LLM calls are bounded by timeout and do not hang indefinitely
- [x] Retries emit structured logs containing `job_id`, `attempt`, and `timeout_seconds`
- [x] Tests cover timeout and retry behavior using a fake LLM client (no network dependency)
- [x] Implementation run log records `ruff check .`, `pytest -q`, and `openspec validate --specs --strict --no-interactive`

## Estimate

- 4-6h

## Completion

- PR: https://github.com/Leeky1017/SS/pull/85
- Notes:
  - `src/config.py` adds `SS_LLM_TIMEOUT_SECONDS` / `SS_LLM_MAX_ATTEMPTS` / backoff settings
  - `src/infra/llm_tracing.py` enforces timeout + retries and emits structured logs on timeout/retry/final failure
  - `tests/test_llm_tracing.py` adds a timeout + retry regression test (fake LLM client)
- Run log: `openspec/_ops/task_runs/ISSUE-82.md`
