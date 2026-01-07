# Phase 4.5: Template Code Quality Audit — Regression (TD* + TE*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TD*` + `TE*` (~22 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make regression templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style** (explicit diagnostics for common failure modes).

## In scope

- Run Stata 18 harness for `TD*` and `TE*`; fix runtime errors and fragile assumptions.
- Handle common regression failure modes with explicit `warn/fail`: collinearity, perfect prediction, insufficient DOF, non-convergence.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Methodological best-practice upgrades (robust inference defaults, richer diagnostics) beyond “runs + auditable” (Phase 5).
- Taxonomy/index changes (Phases 0–2).

## Acceptance checklist

- [ ] Stata 18 baseline run: 0 `fail` across `TD*` + `TE*`
- [ ] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [ ] Common failure modes produce explicit `warn/fail` with `SS_RC` context
- [ ] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

