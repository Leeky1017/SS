# Proposal: issue-507-audit-gaps-505

## Why
PR #506 (Closes #505) delivered the audit-grade real E2E runner and Windows release gate, but a few follow-up gaps remain:
- `openspec/_ops/task_runs/ISSUE-505.md` still shows stale “next steps” despite PR merged
- Rulebook task for #505 is not archived / not marked completed
- `scripts/ss_windows_release_gate_support.py` exceeds the 300 LOC file limit
- Post-restart recoverability does not assert artifacts indexability (`GET /v1/jobs/{job_id}/artifacts`)

## What Changes
- Update `openspec/_ops/task_runs/ISSUE-505.md` to reflect merge state and remove stale next steps.
- Archive `rulebook/tasks/issue-505-real-e2e-audit-gate` under `rulebook/tasks/archive/...` and mark it completed.
- Split the release-gate support module into smaller, focused modules.
- Strengthen restart/recoverability checks:
  - fail the gate if `schtasks` indicates failure (no forced success)
  - after restart, assert artifacts are indexable and `plan.json` is downloadable + parseable

## Impact
- Affected specs: `openspec/specs/ss-production-e2e-audit/spec.md`
- Affected code: `scripts/ss_windows_release_gate.py`, release-gate support modules
- Breaking change: NO (ops gate becomes stricter on failures)
- User benefit: Release gate evidence matches the audit spec (indexable + downloadable artifacts after restart) and avoids false-positive restarts.
