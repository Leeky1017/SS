# Phase 4.10: Template Code Quality Audit — Finance (TK*)

## Metadata

- Issue: #280
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TK*` (~20 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make finance templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for `TK*`; fix runtime errors.
- Defensive checks: panel/time settings (as applicable), missingness, extreme values/weights; explicit `warn/fail`.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Finance-method best-practice upgrades (e.g., HAC defaults, robust reporting) beyond “runs + auditable” (Phase 5).

## Acceptance checklist

- [x] Stata 18 baseline run: 0 `fail` across `TK*`
- [x] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [x] Code style is normalized across the scope
- [x] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-280.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/291
- Smoke suite: `rulebook/tasks/issue-280-phase-4-10-finance-tk/evidence/smoke_suite_report.issue-280.rerun11.json` (`passed: 20`)
- Anchors: removed legacy `SS_*:` / `SS_WARNING:` / `SS_ERROR:` in TK01–TK20; standardized to `SS_EVENT|k=v`
- Run log: `openspec/_ops/task_runs/ISSUE-280.md`
