# Phase 5.4: Template Content Enhancement — Descriptive (TB* + TC*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TB*` + `TC*` (~20 templates, current inventory)
- Depends on:
  - Phase 4.4 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance descriptive-statistics templates with best practices (最佳实践), Stata 18-native outputs, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: clear default summaries, missingness reporting, and reproducible settings.
- Replace SSC output tooling with Stata 18 `collect`/`etable`/`putexcel` where feasible.
- Error handling enhancements: systematic input checks + explicit `warn/fail` policy.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new SSC dependencies.

## Acceptance checklist

- [ ] Each template has a best-practice review record
- [ ] Outputs are upgraded with Stata 18-native tooling where feasible
- [ ] Error handling and diagnostics are strengthened (no silent failure)
- [ ] Key steps have bilingual comments (中英文注释)
- [ ] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

