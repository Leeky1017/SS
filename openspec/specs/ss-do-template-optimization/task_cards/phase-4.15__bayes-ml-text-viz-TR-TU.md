# Phase 4.15: Template Code Quality Audit — Bayes + ML + Text + Viz (TR*–TU*)

## Metadata

- Issue: #355
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TR*` + `TS*` + `TT*` + `TU*` (~47 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make Bayes/ML/text/viz templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for all templates in scope; fix runtime errors.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.
- Because the current inventory is larger than the per-task target, execute in two work packages (可并行):
  - Package A: `TR*` + `TS*` (~22 templates)
  - Package B: `TT*` + `TU*` (~25 templates)

## Out of scope

- Best-practice method upgrades and richer diagnostics (Phase 5).
- Adding new SSC dependencies.

## Acceptance checklist

- [x] Stata 18 baseline run: 0 `fail` across `TR*`–`TU*` (packages A+B)
- [x] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [x] Code style is normalized across the scope
- [x] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/360
- Stata 18 smoke-suite: Package A (TR01–TR10 + TS01–TS12) PASS; Package B (TT01–TT10 + TU01–TU14) PASS.
- Anchors normalized: removed legacy `SS_ERROR:` / `SS_ERR:` and standardized to `SS_EVENT|k=v` in scope.
- Run log: `openspec/_ops/task_runs/ISSUE-355.md` (manifests + evidence + commands).
- Inventory note: current template library contains `TU01`–`TU14` (no `TU15`).
