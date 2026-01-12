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

- [ ] Each template has a best-practice review record
- [ ] Outputs are upgraded with Stata 18-native tooling where feasible
- [ ] Error handling and diagnostics are strengthened (no silent failure)
- [ ] Key steps have bilingual comments (中英文注释)
- [ ] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-362.md`
