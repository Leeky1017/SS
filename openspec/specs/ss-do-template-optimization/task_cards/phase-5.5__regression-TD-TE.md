# Phase 5.5: Template Content Enhancement — Regression (TD* + TE*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TD*` + `TE*` (~22 templates, current inventory)
- Depends on:
  - Phase 4.5 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance regression templates with best practices (最佳实践), Stata 18-native tooling (替换 SSC), stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: robust/cluster defaults where appropriate, clearer model assumptions, and minimal diagnostics outputs.
- Replace SSC table tooling with Stata 18 `collect`/`etable`/`putexcel` where feasible.
- Error handling enhancements: explicit handling for collinearity, separation, small samples; `warn/fail` with `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Adding new external dependencies.
- Taxonomy/index changes and placeholder redesign.

## Acceptance checklist

- [ ] Each template has a best-practice review record
- [ ] SSC deps are removed/replaced where feasible (exceptions justified)
- [ ] Error handling and diagnostics are strengthened (no silent failure)
- [ ] Key steps have bilingual comments (中英文注释)
- [ ] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

