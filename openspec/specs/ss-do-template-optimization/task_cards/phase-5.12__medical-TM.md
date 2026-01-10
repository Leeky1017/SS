# Phase 5.12: Template Content Enhancement — Medical / Biostats (TM*)

## Metadata

- Issue: #284
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TM*` (~15 templates, current inventory)
- Depends on:
  - Phase 4.12 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance medical/biostats templates with best practices (最佳实践), Stata 18-native tooling, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: clear assumptions and minimal diagnostics outputs where appropriate.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: small samples, separation, non-convergence with explicit `warn/fail` + `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [x] Each `TM*` template has a best-practice review record
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-284.md`

## Completion
- PR: https://github.com/Leeky1017/SS/pull/286
- Run log: `openspec/_ops/task_runs/ISSUE-284.md`
- Summary:
  - TM01–TM15 add best-practice review notes (EN/ZH) and bilingual step comments
  - Remove SSC deps (TM02/TM06/TM07) and align meta + smoke-suite manifest
  - Strengthen validation/error handling for non-binary inputs, nonpositive SE/exposure, and non-convergence
