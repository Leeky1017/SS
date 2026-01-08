# Phase 5.5: Template Content Enhancement — Regression (TD* + TE*)

## Metadata

- Issue: #192
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TD01`–`TD06`, `TD10`, `TD12` + `TE01`–`TE10` (18 templates, current inventory; `TD07/TD08/TD09/TD11` were removed in Phase 2 dedupe)
- Depends on:
  - Phase 4.5 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance regression templates with best practices (最佳实践), Stata 18-native tooling (替换 SSC), stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: robust/cluster defaults where appropriate, clearer model assumptions, and minimal diagnostics outputs.
- Replace SSC table tooling with Stata 18 `collect`/`etable`/`putexcel` where feasible.
- Error handling enhancements: explicit handling for collinearity, separation, small samples; `warn/fail` with `SS_RC`.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Adding new external dependencies.
- Taxonomy/index changes and placeholder redesign.

## Acceptance checklist

- [x] Each template has a best-practice review record
- [x] SSC deps are removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/199
- Added best-practice review blocks + bilingual guidance across TD01–TD06, TD10, TD12 and TE01–TE10.
- Reduced SSC deps where feasible (TD01 uses base `xtreg, fe`; TE05 uses base two-part model via `logit` + `glm`).
- Kept SSC only when needed (e.g., TE08 `mixlogit`), with clearer failure handling and guidance.
- Run log: `openspec/_ops/task_runs/ISSUE-192.md`
