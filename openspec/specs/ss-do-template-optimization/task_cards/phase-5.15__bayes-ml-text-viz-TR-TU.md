# Phase 5.15: Template Content Enhancement — Bayes + ML + Text + Viz (TR*–TU*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TR*` + `TS*` + `TT*` + `TU*` (~47 templates, current inventory)
- Depends on:
  - Phase 4.15 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance Bayes/ML/text/viz templates with best practices (最佳实践), Stata 18-native tooling (替换 SSC), stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades with explicit decision records per template.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: systematic input checks + explicit `warn/fail` + `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.
- Because the current inventory is larger than the per-task target, execute in two work packages (可并行):
  - Package A: `TR*` + `TS*` (~22 templates)
  - Package B: `TT*` + `TU*` (~25 templates)

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [ ] Each template has a best-practice review record (packages A+B)
- [ ] SSC deps removed/replaced where feasible (exceptions justified)
- [ ] Error handling and diagnostics are strengthened (no silent failure)
- [ ] Key steps have bilingual comments (中英文注释)
- [ ] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

