# Proposal: issue-383-fix-issue-372-evidence-pointers

## Why
Issue #372’s audit evidence lives under an archived Rulebook task path, but the run log still points to the pre-archive location, breaking auditability and reviewer navigation.

## What Changes
- Update `openspec/_ops/task_runs/ISSUE-372.md` to reference the archived evidence path under `rulebook/tasks/archive/`.

## Impact
- Affected specs: none
- Affected code: `openspec/_ops/task_runs/ISSUE-372.md`
- Breaking change: NO
- User benefit: Evidence pointers remain valid after Rulebook task archival.
