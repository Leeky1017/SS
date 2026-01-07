# Proposal: issue-93-concurrency-tests

## Why
Add regression coverage for concurrency race conditions across API/worker/job-store boundaries, so future changes don’t reintroduce lost updates, stale reads, duplicate processing, or partial file reads.

## What Changes
- Add a new `tests/concurrent/` test suite implementing scenarios 1–4 defined in `openspec/specs/ss-testing-strategy/README.md`.
- Introduce minimal shared fixtures for deterministic multi-thread/process concurrency tests.
- Ensure tests are stable under repeat runs (`--count=10`) and validate atomic file write behavior.

## Impact
- Affected specs:
  - `openspec/specs/ss-testing-strategy/README.md`
  - `openspec/specs/ss-testing-strategy/task_cards/concurrent.md`
- Affected code:
  - `tests/concurrent/`
- Breaking change: NO
- User benefit: Concurrency regressions are caught before shipping, improving correctness and trust in job state/results.
