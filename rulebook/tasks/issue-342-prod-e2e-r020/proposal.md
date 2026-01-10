# Proposal: issue-342-prod-e2e-r020

## Why
The production E2E audit (F002) requires that SSC/ado dependencies declared by a do-template are (1) visible in the frozen plan for ops preflight and (2) diagnosable at run time so operators can fix the environment and retry deterministically. Silent or opaque missing-dependency failures break auditability and repeatability.

## What Changes
- Add a worker-side Stata dependency preflight based on the frozen plan’s declared dependencies.
- When dependencies are missing, fail the run attempt before execution with `error_code=STATA_DEPENDENCY_MISSING` and include `details.missing_dependencies[]` in `run.error.json`.
- Allow retrying a `failed` job via `POST /v1/jobs/{job_id}/run` (re-queue same job, create a new run attempt).

## Non-goals
- No runtime auto-install of SSC packages (network/supply-chain/reproducibility risk).

## Impact
- Affected code: worker pre-run execution (`src/domain/worker_plan_executor.py`), job retry semantics (`src/domain/job_service.py`, `src/domain/state_machine.py`), run error artifacts (`src/infra/stata_run_*`).
- Affected specs: `openspec/specs/ss-state-machine/spec.md` (add explicit retry transition).
- Evidence: `openspec/_ops/task_runs/ISSUE-342.md`.
