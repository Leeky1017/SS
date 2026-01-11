# Proposal: issue-354-phase-4-14-panel-hlm-tp-tq

## Why
- Phase 4 requires every template to run under a real Stata 18 smoke-suite harness with fixtures; TP/TQ are still emitting legacy anchors and may fail on common panel/HLM preconditions.

## What Changes
- Add a TP/TQ-scoped smoke-suite manifest (fixtures + params + deps) and run the Stata 18 harness.
- Fix runtime failures to reach 0 `failed` within TP01–TP15 and TQ01–TQ12.
- Normalize anchors to `SS_EVENT|k=v` per `assets/stata_do_library/SS_DO_CONTRACT.md` (remove legacy `SS_*:` variants).
- Add explicit warn/fail diagnostics for common panel + HLM failure modes (with `SS_RC` context).

## Impact
- Stata templates: `assets/stata_do_library/do/TP01`–`TP15`, `TQ01`–`TQ12`
- Smoke-suite manifest: `assets/stata_do_library/smoke_suite/manifest.issue-354.*.json`
- Evidence + run log: `rulebook/tasks/issue-354-phase-4-14-panel-hlm-tp-tq/evidence/` and `openspec/_ops/task_runs/ISSUE-354.md`

