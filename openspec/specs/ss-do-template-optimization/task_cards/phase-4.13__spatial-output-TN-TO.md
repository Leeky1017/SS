# Phase 4.13: Template Code Quality Audit — Spatial + Output (TN* + TO*)

## Metadata

- Issue: #353
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TN*` + `TO*` (~18 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make spatial and output/reporting templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for `TN*` and `TO*`; fix runtime errors.
- Defensive checks: required spatial identifiers/files and output paths; explicit `warn/fail`.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Output “polish” upgrades (tables/figures/report layouts) beyond “runs + auditable” (Phase 5).

## Acceptance checklist

- [x] Stata 18 baseline run: 0 `fail` across `TN*` + `TO*`
- [x] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [x] Output files are declared consistently and paths are safe (no hardcoded local paths)
- [x] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-353.md`

## Completion

- PR: <fill-after-merged>
- Run log: `openspec/_ops/task_runs/ISSUE-353.md`
- Evidence: `rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun04.json`
