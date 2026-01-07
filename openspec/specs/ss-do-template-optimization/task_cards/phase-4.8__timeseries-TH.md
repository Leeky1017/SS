# Phase 4.8: Template Code Quality Audit — Time Series (TH*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TH*` (~15 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make time-series templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for `TH*`; fix runtime errors.
- Defensive checks: `tsset` preconditions, gaps, sample size for lags/orders, non-stationary cases handled explicitly (warn/fail when required).
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Best-practice time-series method upgrades (order selection, diagnostics outputs) beyond “runs + auditable” (Phase 5).

## Acceptance checklist

- [ ] Stata 18 baseline run: 0 `fail` across `TH*`
- [ ] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [ ] Time-series preconditions are validated with explicit `warn/fail`
- [ ] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

