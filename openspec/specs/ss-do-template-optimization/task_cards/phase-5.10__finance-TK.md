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

- [x] Each `TK*` template has a best-practice review record
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-296.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/303
- Summary:
  - Added `SS_BEST_PRACTICE_REVIEW` blocks to TK01–TK20
  - Added missingness/scale/parameter-default warnings for common finance pitfalls
  - Ran Stata 18 smoke-suite for TK01–TK20 (all passed)
- Run log: `openspec/_ops/task_runs/ISSUE-296.md`
