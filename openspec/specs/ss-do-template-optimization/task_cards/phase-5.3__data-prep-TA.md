# Phase 5.3: Template Content Enhancement — Data Prep (TA*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TA*` (~14 templates, current inventory)
- Depends on:
  - Phase 4.3 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance data-prep templates with best practices (最佳实践), Stata 18-native choices (替换 SSC), stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: robust data checks, clear assumptions, deterministic preprocessing.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; explicitly justify any exceptions.
- Error handling enhancements: strict input validation + explicit `warn/fail` with `SS_RC` context.
- Bilingual comments (中英文注释) for key steps and common pitfalls.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [ ] Each `TA*` template has a best-practice review record
- [ ] SSC deps removed/replaced where feasible (exceptions justified)
- [ ] Error handling and diagnostics are strengthened (no silent failure)
- [ ] Key steps have bilingual comments (中英文注释)
- [ ] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

