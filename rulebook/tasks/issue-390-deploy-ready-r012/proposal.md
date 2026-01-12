# Proposal: issue-390-deploy-ready-r012

## Why
SS production deployments need a clear, executable Stata provisioning strategy. Without a documented mount/path contract and fail-fast startup behavior, worker containers can start in a misconfigured state and only fail later at runtime, blocking deploy readiness and making incidents harder to diagnose.

## What Changes
- Document the recommended Stata provisioning approach for production (host-mounted strategy) including a stable mount path and `SS_STATA_CMD` contract.
- Add a runnable docker-compose example that demonstrates the host mount wiring.
- Tighten worker startup gating so missing/invalid Stata configuration fails fast with a structured error.
- Record evidence in `openspec/_ops/task_runs/ISSUE-390.md` and update the task card metadata.

## Impact
- Affected specs:
  - `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Affected code:
  - `src/worker.py`
- Breaking change: NO (only misconfigured worker deployments fail earlier with clearer errors)
- User benefit: operators get a repeatable Stata provisioning recipe and immediate, diagnosable worker startup failures when Stata is not correctly mounted/configured.
