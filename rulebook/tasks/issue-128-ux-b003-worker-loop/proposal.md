# Proposal: issue-128-ux-b003-worker-loop

## Why
Worker currently cannot produce user-meaningful results: it generates a stub do-file and always uses `FakeStataRunner`, so it never executes DoFileGenerator + real Stata and cannot output exported result artifacts.

## What Changes
- Worker executes a queued job by loading `job.llm_plan`, loading the inputs manifest, generating `stata.do` via `DoFileGenerator`, and running via a configurable StataRunner (Local vs Fake).
- Pre-run failures (missing plan / missing inputs manifest) still write run evidence artifacts (`run.meta.json` + `run.error.json` etc) under `runs/<run_id>/artifacts`.
- Fake runner now produces a minimal export-table artifact for dev/test parity.
- Update user journey + worker tests to cover success artifacts (do/log/meta/export) and failure evidence.

## Impact
- Affected specs:
  - `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B003.md`
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
- Affected code:
  - `src/worker.py`
  - `src/domain/worker_plan_executor.py`
  - `src/domain/worker_service.py`
  - `src/infra/fake_stata_runner.py`
  - `tests/user_journeys/*`
  - `tests/test_worker_service.py`
