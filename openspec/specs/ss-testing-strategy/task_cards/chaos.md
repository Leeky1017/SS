# Chaos — Task Card

## Goal

Implement chaos tests that validate SS behavior under resource exhaustion and dependency failures, based on the chaos items referenced by `openspec/specs/ss-testing-strategy/README.md`.

## In scope

- Create `tests/chaos/` and shared fault-injection fixtures (`tests/chaos/conftest.py`).
- Add tests for:
  - disk full during save / artifact writes
  - permission loss / non-writable workspace
  - dependency unavailability (e.g., LLM timeouts)
  - memory pressure/OOM handling (as far as deterministic simulation allows)
- Assertions focus on: user-friendly errors, no data corruption, auditable logs/artifacts.

## Dependencies & parallelism

- Depends on structured errors + logging baseline: `openspec/specs/ss-observability/spec.md`
- Depends on security red lines (no sensitive leakage): `openspec/specs/ss-security/spec.md`
- Depends on LLM behavior boundaries: `openspec/specs/ss-llm-brain/spec.md`
- Depends on job store artifact semantics: `openspec/specs/ss-job-contract/spec.md`

## Acceptance checklist

- [x] `tests/chaos/` contains chaos test modules referenced by the strategy README
- [x] Disk/permission/LLM failure paths return clear, stable error responses (no traceback leaks)
- [x] Failures do not corrupt persisted job state or artifacts
- [x] Fault injection is explicit and does not rely on environment flakiness
