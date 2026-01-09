# Phase 5.6: Template Content Enhancement — Panel Advanced (TF*)

## Metadata

- Issue: #246
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TF*` (~14 templates, current inventory)
- Depends on:
  - Phase 4.6 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance advanced panel templates with best practices (最佳实践), Stata 18-native tooling, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: clearer FE/RE strategy, inference defaults, and minimal diagnostics where appropriate.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: explicit checks for panel structure, singleton groups, weak within variation.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [x] Each `TF*` template has a best-practice review record
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-246.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/253
- Run log: `openspec/_ops/task_runs/ISSUE-246.md`
- Summary:
  - Added Phase 5.6 best-practice review blocks + bilingual guidance across TF01–TF14.
  - Made `TF04_xtscc.do` treat `xtscc` as optional, with built-in fallback.
  - Updated meta and smoke manifest to match dependency strategy.
