# Phase 5.9: Template Content Enhancement — Survival + Multivariate (TI* + TJ*)

## Metadata

- Issue: #295
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TI*` + `TJ*` (~17 templates, current inventory)
- Depends on:
  - Phase 4.9 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance survival and multivariate templates with best practices (最佳实践), Stata 18-native tooling, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: explicit modeling assumptions and minimal diagnostics outputs where appropriate.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: small event counts, separation, non-convergence with explicit `warn/fail` + `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [x] Each template has a best-practice review record
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-295.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/302
- Summary:
  - Added `SS_BEST_PRACTICE_REVIEW` blocks to TI01–TI11 and TJ01–TJ06
  - Strengthened PH/competing-risk diagnostics and guardrails
  - Ran Stata 18 smoke-suite; only missing dep is SSC `stcure` for TI09
- Run log: `openspec/_ops/task_runs/ISSUE-295.md`
