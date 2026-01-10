# Proposal: issue-278-p4-11-12-closeout

## Why
Close out P4.11/P4.12 delivery by ensuring task cards, run logs, and Rulebook task archival are complete and auditable on `main`.

## What Changes
- Backfill acceptance + completion sections in P4.11 (TL) and P4.12 (TM) task cards.
- Update run logs for #272/#273 to reflect merged state.
- Archive Rulebook tasks for #272/#273 under `rulebook/tasks/archive/`.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.11__accounting-TL.md`, `openspec/specs/ss-do-template-optimization/task_cards/phase-4.12__medical-TM.md`
- Affected code: `openspec/_ops/task_runs/ISSUE-272.md`, `openspec/_ops/task_runs/ISSUE-273.md`, `rulebook/tasks/**`
- Breaking change: NO
- User benefit: Task audit trail is complete (acceptance, completion, archival) without leaving “done but not recorded” gaps.
