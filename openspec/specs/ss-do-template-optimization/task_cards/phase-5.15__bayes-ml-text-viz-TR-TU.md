# Phase 5.15: Template Content Enhancement — Bayes + ML + Text + Viz (TR*–TU*)

## Metadata

- Issue: #364
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

- [x] Each template has a best-practice review record (packages A+B)
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-364.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/373
- Added bilingual `BEST_PRACTICE_REVIEW` blocks across TR/TS/TT/TU templates; strengthened validation + `SS_RC` fail-fast behavior.
- Replaced remaining feasible SSC dependency: TU11 now implements RIF regression with built-in `_pctile` + `kdensity` + `regress`.
- Hardened optional numeric parameters to avoid invalid Stata syntax when placeholders are omitted.
- Run log: `openspec/_ops/task_runs/ISSUE-364.md`
