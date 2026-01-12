# Phase 5.14: Template Content Enhancement — Panel + HLM (TP* + TQ*)

## Metadata

- Issue: #363
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TP*` + `TQ*` (~27 templates, current inventory)
- Depends on:
  - Phase 4.14 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance panel and hierarchical-model templates with best practices (最佳实践), Stata 18-native tooling, stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: clearer FE/RE/HLM strategy, inference defaults, and minimal diagnostics outputs.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: convergence and data-shape checks with explicit `warn/fail` + `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Taxonomy/index changes and placeholder redesign.
- Adding new external dependencies.

## Acceptance checklist

- [x] Each template has a best-practice review record
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-363.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/369
- Summary:
  - Added Phase 5.14 review blocks + `SS_BP_REVIEW|issue=363` anchors for TP01–TP15 and TQ01–TQ12.
  - Strengthened preflight validation + explicit warn/fail error handling (`SS_RC`) for panel/ts/HLM workflows.
  - Kept required SSC deps with explicit checks + rationale where no safe built-in alternative exists (e.g., `xtabond2`, `xtserial`).
- Run log: `openspec/_ops/task_runs/ISSUE-363.md`
