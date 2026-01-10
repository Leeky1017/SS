# Phase 5.11: Template Content Enhancement — Accounting / Audit (TL*)

## Metadata

- Issue: #283
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TL*` (~15 templates, current inventory)
- Depends on:
  - Phase 4.11 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance accounting/audit templates with best practices (最佳实践), Stata 18-native tooling, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: clearer assumptions and minimal diagnostics outputs where appropriate.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: strict input validation + explicit `warn/fail` + `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [x] Each `TL*` template has a best-practice review record
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-283.md`

## Completion
- PR: https://github.com/Leeky1017/SS/pull/285
- Run log: `openspec/_ops/task_runs/ISSUE-283.md`
- Summary:
  - TL01–TL15 add best-practice review notes (EN/ZH) and bilingual step comments
  - Strengthen validation and explicit `SS_RC` handling (fail-fast on model/predict failures)
  - Verified via `ruff` and `pytest` (see run log)
