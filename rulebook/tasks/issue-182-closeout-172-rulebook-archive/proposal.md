# Proposal: issue-182-closeout-172-rulebook-archive

## Why
Issue #172 is merged (PR #180). Per the delivery workflow, the corresponding Rulebook task directory should be archived to keep the active task list clean and reduce drift.

## What Changes
- Move `rulebook/tasks/issue-172-p44-p45-tb-tc-td-te-audit/` into `rulebook/tasks/archive/<date>-issue-172-p44-p45-tb-tc-td-te-audit/` via `git mv`.
- Record evidence in `openspec/_ops/task_runs/ISSUE-182.md`.

## Impact
- Affected specs: none (closeout only)
- Affected code:
  - `rulebook/tasks/**` (Rulebook task archival)
  - `openspec/_ops/task_runs/ISSUE-182.md` (evidence)
- Breaking change: NO
- User benefit: repository hygiene; keeps active Rulebook task list minimal and auditable.
