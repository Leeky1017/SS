# Phase 5.13: Template Content Enhancement — Spatial + Output (TN* + TO*)

## Metadata

- Issue: #362
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TN*` + `TO*` (~18 templates, current inventory)
- Depends on:
  - Phase 4.13 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance spatial and output/reporting templates with best practices (最佳实践), Stata 18-native tooling, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: safer output/export conventions; minimal diagnostics outputs where appropriate.
- Replace SSC output tooling with Stata 18 `collect`/`etable`/`putexcel`/`putdocx` where feasible.
- Error handling enhancements: strict file/path checks + explicit `warn/fail` + `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [x] Each template has a best-practice review record
- [x] Outputs are upgraded with Stata 18-native tooling where feasible
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-362.md`

## Completion
- PR: https://github.com/Leeky1017/SS/pull/367
- Run log: `openspec/_ops/task_runs/ISSUE-362.md`
- Summary:
  - TN01–TN10 + TO01–TO08 add Phase 5.13 best-practice review blocks (`SS_BP_REVIEW`) and bilingual step comments
  - TO* output templates prefer Stata 18-native `collect`/`etable`/`putdocx`/`putexcel` paths and reduce SSC deps where feasible
  - Update `*.meta.json` outputs/deps and regenerate `assets/stata_do_library/DO_LIBRARY_INDEX.json`
