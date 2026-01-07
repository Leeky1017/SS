# Proposal: issue-103-stress-tests

## Why
We need repeatable stress tests to validate SS performance and resource stability under high concurrency,
long runtimes, and boundary inputs (as defined in `openspec/specs/ss-testing-strategy/README.md`).

## What Changes
- Add `tests/stress/` modules for stress scenarios 1/2/4 (load, stability, boundary inputs).
- Add baseline metrics collection (p99 latency, error rate, RSS, open fd count) as JSON test reports.
- Keep stress tests skipped-by-default and configurable via env vars for dedicated environments.

## Impact
- Affected specs:
  - `openspec/specs/ss-testing-strategy/README.md` (existing references; tests implemented here)
  - `openspec/specs/ss-testing-strategy/task_cards/stress.md`
- Affected code:
  - `tests/stress/`
  - `pyproject.toml` (add `pytest-benchmark` to dev deps)
- Breaking change: NO
- User benefit: Dedicated performance/regression guardrails for concurrency and scale boundaries.
