# Phase 4.6: Template Code Quality Audit — Panel Advanced (TF*)

## Metadata

- Issue: #240
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TF*` (~14 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make advanced panel templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for `TF*`; fix runtime errors.
- Defensive checks for panel settings: time/id variable validation, unbalanced panels, singleton groups, insufficient within variation.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Best-practice method redesigns (diagnostics/inference upgrades) beyond “runs + auditable” (Phase 5).

## Acceptance checklist

- [ ] Stata 18 baseline run: 0 `fail` across `TF*`
- [ ] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [ ] Panel preconditions are validated with explicit `warn/fail` on violations
- [ ] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`
