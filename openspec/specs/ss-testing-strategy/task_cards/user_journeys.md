# User Journeys — Task Card

## Goal

Implement user-journey tests that validate SS behavior at the level a real user experiences (state continuity, idempotency, recovery), using the A–D scenarios defined in `openspec/specs/ss-testing-strategy/README.md`.

Issue: #94

## In scope

- Create `tests/user_journeys/` and shared fixtures (`tests/user_journeys/conftest.py`).
- Add tests for:
  - A: complete analysis flow (upload → preview → draft → preview loop → submit → poll → download)
  - B: draft modification loop (multiple previews + parameter edits)
  - C: page reload / network jitter recovery (idempotency + resume)
  - D: duplicate submission (rapid clicks / retry)
- Assertions focus on: stable API responses, correct state transitions, no duplicate jobs, recoverable errors.

## Dependencies & parallelism

- Depends on stable API contracts: `openspec/specs/ss-api-surface/spec.md`
- Depends on state/idempotency rules: `openspec/specs/ss-state-machine/spec.md`
- Depends on job contract + artifacts: `openspec/specs/ss-job-contract/spec.md`
- Recommended pairing: `openspec/specs/ss-llm-brain/spec.md`, `openspec/specs/ss-stata-runner/spec.md`

## Acceptance checklist

- [x] `tests/user_journeys/` contains A–D test modules referenced by the strategy README
- [x] Tests validate state continuity across steps (`job_id` persists; `draft` and artifacts evolve)
- [x] Duplicate/rapid submissions do not create duplicated jobs (or are explicitly rejected)
- [x] Recovery cases (reload / retry) are idempotent and do not corrupt job state

## Completion

- PR: https://github.com/Leeky1017/SS/pull/98
- Added A–D user journey tests under `tests/user_journeys/`
- Verified locally: `.venv/bin/ruff check .`, `.venv/bin/pytest -q`
- Run log: `openspec/_ops/task_runs/ISSUE-94.md`
