# Phase 4.11: Template Code Quality Audit — Accounting / Audit (TL*)

## Metadata

- Issue: #272
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TL*` (~15 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make accounting/audit templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for `TL*`; fix runtime errors.
- Defensive checks: required variables/files, sample constraints, missingness; explicit `warn/fail`.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Best-practice method upgrades and reporting polish (Phase 5).

## Acceptance checklist

- [x] Stata 18 baseline run: 0 `fail` across `TL*`
- [x] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [x] Code style is normalized across the scope
- [x] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-272.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/275
- Summary:
  - Added TL smoke-suite manifest + fixture dataset (TL01–TL15)
  - Fixed Stata batch failures (BOM `r(199)`, one-line braces `r(198)`, `logit` perfect prediction `r(2000)`)
  - Normalized anchors to pipe-delimited `SS_*|k=v` and unified template style
- Run log: `openspec/_ops/task_runs/ISSUE-272.md`
