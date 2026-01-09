# Phase 5.8: Template Content Enhancement — Time Series (TH*)

## Metadata

- Issue: #263
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TH*` (~15 templates, current inventory)
- Depends on:
  - Phase 4.8 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance time-series templates with best practices (最佳实践), Stata 18-native tooling, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: explicit `tsset` assumptions, minimal diagnostics outputs (e.g., residual checks) where appropriate.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: gaps/order constraints, small samples, non-stationarity flags with explicit `warn/fail`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [x] Each `TH*` template has a best-practice review record
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-263.md`

## Completion
- PR: https://github.com/Leeky1017/SS/pull/266
- Updated templates: TH01–TH04, TH06–TH09, TH11–TH15 (repo truth: TH05/TH10 were deleted earlier and remain out-of-scope here).
- Removed SSC dep `asreg` from TH14 and aligned meta + smoke-suite manifest.
- Added best-practice review anchors (`SS_BP_REVIEW`) + stronger `tsset`/gap preflight + explicit warn/fail paths.
- Run log: `openspec/_ops/task_runs/ISSUE-263.md`
