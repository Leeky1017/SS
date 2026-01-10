# Phase 5.10: Template Content Enhancement — Finance (TK*)

## Metadata

- Issue: #296
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TK*` (~20 templates, current inventory)
- Depends on:
  - Phase 4.10 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance finance templates with best practices (最佳实践), Stata 18-native tooling, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: clear inference choices (robust/cluster/HAC where relevant) and minimal diagnostics outputs.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: data-shape constraints, missingness/extreme values with explicit `warn/fail` + `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [ ] Each `TK*` template has a best-practice review record
- [ ] SSC deps removed/replaced where feasible (exceptions justified)
- [ ] Error handling and diagnostics are strengthened (no silent failure)
- [ ] Key steps have bilingual comments (中英文注释)
- [ ] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

