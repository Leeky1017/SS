# Stress — Task Card

## Goal

Implement stress tests that validate SS performance and stability under load, long runtimes, and boundary data volumes, based on stress scenarios 1–4 in `openspec/specs/ss-testing-strategy/README.md`.

## In scope

- Create `tests/stress/` and basic resource/perf fixtures (`tests/stress/conftest.py`).
- Add tests for:
  - 1: high concurrency load (upload + execution + status polling)
  - 2: long-running stability (hour-scale / day-scale runs)
  - 4: boundary data volume (large dataset, long inputs, many columns)
- Record baseline metrics (p99 latency, error rate, memory/fd usage) as test outputs.

## Dependencies & parallelism

- Depends on stable API contracts: `openspec/specs/ss-api-surface/spec.md`
- Depends on runner/work execution: `openspec/specs/ss-stata-runner/spec.md`, `openspec/specs/ss-worker-queue/spec.md`
- Depends on observability baselines: `openspec/specs/ss-observability/spec.md`

## Acceptance checklist

- [ ] `tests/stress/` contains 1/2/4 test modules referenced by the strategy README
- [ ] Tests collect and report baseline metrics (latency/error/resource)
- [ ] Stress tests have clear runtime bounds and are runnable in a dedicated environment
