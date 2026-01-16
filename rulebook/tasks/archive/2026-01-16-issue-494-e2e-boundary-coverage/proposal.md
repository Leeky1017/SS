# Proposal: issue-494-e2e-boundary-coverage

## Why
- `tests/e2e/COVERAGE.md` lists known boundary gaps for inputs, LLM output handling, and execution.
- These are high-risk edges (real user files + provider variability) that should be locked by E2E tests to prevent regressions.

## What Changes
- Add E2E tests under `tests/e2e/layer2_inputs/`, `tests/e2e/layer3_llm/`, and `tests/e2e/layer5_execution/` to cover the known gaps.
- Where behavior is missing/incorrect, add an expected-failure E2E test first, then fix in the same PR (or create a follow-up Issue and record it in `tests/e2e/FINDINGS.md`).
- Update `tests/e2e/COVERAGE.md` to reflect the expanded coverage.

## Impact
- Affected specs:
  - `rulebook/tasks/issue-494-e2e-boundary-coverage/specs/ss-e2e-boundary-coverage/spec.md`
  - `openspec/specs/ss-testing-strategy/README.md` (reference only; no changes planned)
- Affected code:
  - `tests/e2e/**`
  - `src/domain/**` / `src/infra/**` (only if a gap requires a fix)
  - `ERROR_CODES.md` (only if new stable error codes are introduced)
- Breaking change: NO (error behavior may become more explicit)
- User benefit: clearer, stable error codes/messages for boundary inputs and malformed LLM outputs; execution failures become more diagnosable.
