# Proposal: issue-418-worker-coverage

## Why
Worker internals are on the critical execution path but currently have low coverage, so regressions in claim handling, retry decisions, and pre-run failure behavior can land unnoticed.

## What Changes
- Add focused unit tests for worker internals and key error paths.
- Keep tests deterministic by using fakes/mocks only at external boundaries.

## Impact
- Affected specs: none (task-scoped spec delta only)
- Affected code: `src/worker.py` and supporting worker modules; new tests under `tests/`
- Breaking change: NO
- User benefit: Safer worker changes with fast feedback and fewer production regressions.
