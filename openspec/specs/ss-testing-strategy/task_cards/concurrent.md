# Concurrency — Task Card

## Goal

Implement concurrency tests that catch race conditions across API/worker/job-store boundaries, based on the 1–4 scenarios defined in `openspec/specs/ss-testing-strategy/README.md`.

## In scope

- Create `tests/concurrent/` and shared fixtures (`tests/concurrent/conftest.py`).
- Add tests for:
  - 1: concurrent job modifications (conflict policy / atomic read-modify-write)
  - 2: state visibility while worker updates job progress
  - 3: multi-worker queue fairness (no duplicates / no missing / no deadlocks)
  - 4: atomic file operations under concurrent save/load
- Use repeat runs (e.g., `pytest --count=10`) to make races reproducible.

## Dependencies & parallelism

- Depends on worker/queue semantics: `openspec/specs/ss-worker-queue/spec.md`
- Depends on state/idempotency rules: `openspec/specs/ss-state-machine/spec.md`
- Depends on job store + atomic write guarantees: `openspec/specs/ss-job-contract/spec.md`

## Acceptance checklist

- [ ] `tests/concurrent/` contains 1–4 test modules referenced by the strategy README
- [ ] Tests are deterministic enough to run repeatedly and reliably catch regressions
- [ ] Atomic save/load never produces partial/corrupted reads
- [ ] Multi-worker execution shows no duplicated processing for the same job
