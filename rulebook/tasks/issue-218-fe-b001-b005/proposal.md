# Proposal: issue-218-fe-b001-b005

## Why
Step 3 “分析蓝图预检” currently renders static placeholders and lacks the legacy-validated confirmation flow (variable corrections, clarification gating, warnings, confirm lockdown), blocking the v1 `/v1/jobs/{job_id}/draft/*` UX loop.

## What Changes
- Upgrade `index.html` Step 3 UI to load draft preview (with 202 pending polling) and render:
  - variable corrections dropdowns + clear
  - stage1 questions + open_unknowns inputs + patch flow
  - data quality warnings panel
  - confirm gating + downgrade-risk modal + locked read-only state

## Impact
- Affected specs:
  - `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Affected code:
  - `index.html`
  - `assets/` (new CSS/JS extracted from index.html)
  - `openspec/_ops/task_runs/ISSUE-218.md`
- Breaking change: NO (frontend-only; API calls best-effort with graceful error states)
- User benefit: users can correct variables and resolve blockers before confirming; confirmation locks contract to prevent duplicate edits.
