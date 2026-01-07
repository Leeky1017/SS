# Phase 4.4: Template Code Quality Audit — Descriptive (TB* + TC*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TB*` + `TC*` (~20 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make descriptive-statistics templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for `TB*` and `TC*`; fix all runtime errors.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers, indentation, macro naming, step boundaries.
- Defensive checks: missingness/type validation and empty-sample handling with explicit `warn/fail`.

## Out of scope

- Output polish and best-practice reporting upgrades (Phase 5).
- Taxonomy/index changes (Phases 0–2).

## Acceptance checklist

- [ ] Stata 18 baseline run: 0 `fail` across `TB*` + `TC*`
- [ ] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [ ] Code style is normalized across the scope
- [ ] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

