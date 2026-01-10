# Proposal: PROD-E2E-R042 — remove FakeStataRunner fallback

## Context

- Finding: `PROD-E2E-F004` (`openspec/_ops/task_runs/ISSUE-274.md`)
- Task card: `openspec/specs/ss-production-e2e-audit-remediation/task_cards/round-01-prod-a__PROD-E2E-R042.md`

## Change

- Worker startup no longer falls back to a fake runner when `SS_STATA_CMD` is missing.
- Worker fails fast with a stable `error_code` and structured log context when `SS_STATA_CMD` is not configured.
- Tests that need a fake runner use an injected fake implementation under `tests/**`.

## Impact

- Production safety: prevents silently running without real Stata execution.
- Testing: preserves fast tests via injected fakes; runtime no longer ships a fake runner.

