# Proposal: issue-261-p48-task-card-closeout-th

## Why
The Phase 4.8 task card must be closed out after the Phase 4.8 remediation PR merged (per SS delivery workflow), and the archived Rulebook task state must be committed.

## What Changes
- Backfill Phase 4.8 task card acceptance checklist and add a Completion section referencing PR #260 and the run log for Issue #255.
- Commit the Rulebook archive move for `issue-255-phase-4-8-timeseries-th`.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.8__timeseries-TH.md`
- Affected code:
  - `rulebook/tasks/archive/2026-01-09-issue-255-phase-4-8-timeseries-th/`
  - `openspec/_ops/task_runs/ISSUE-261.md`
- Breaking change: NO
- User benefit: Phase 4.8 is auditable end-to-end (checked acceptance + completion pointer + archived task state).
