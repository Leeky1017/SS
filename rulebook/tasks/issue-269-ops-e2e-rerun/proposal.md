# Proposal: issue-269-ops-e2e-rerun

## Why
We need fresh end-to-end evidence on latest `main` that the v1 UX loop still works and that Opus 4.5 now auto-populates draft variable fields (outcome/treatment/controls) without requiring manual patch.

## What Changes
- No product code changes expected.
- Run a full v1 journey locally and record commands + key outputs in `openspec/_ops/task_runs/ISSUE-269.md`.

## Impact
- Affected specs: None (evidence-only run log)
- Affected code: None (expected)
- Breaking change: NO
- User benefit: Higher confidence before launch; regression guard via recorded evidence
