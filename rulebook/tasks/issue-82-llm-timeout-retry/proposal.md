# Proposal: issue-82-llm-timeout-retry

## Why
The audit flagged that LLM calls have no explicit timeout and retry policy, which can lead to indefinite hangs or fragile failures under transient network/provider instability.

## What Changes
- Define explicit, configurable LLM timeout + retry/backoff settings in `src/config.py`.
- Enforce timeout and retries around the LLM call entrypoint (infra adapter), so domain logic stays provider-agnostic.
- Emit structured logs for timeouts/retries and final failures (include `job_id`, `attempt`, `timeout_seconds`).
- Add tests for timeout/retry behavior using a fake LLM client (no network dependency).

## Impact
- Affected specs: none (already captured in `openspec/specs/ss-audit-remediation/spec.md`)
- Affected code: `src/config.py`, `src/api/deps.py`, `src/infra/llm_tracing.py`, tests
- Breaking change: NO (defaults preserve current behavior; only adds bounded execution + retries)
- User benefit: prevents indefinite hangs and improves reliability under transient failures

