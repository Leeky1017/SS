# Phase 4.3: Template Code Quality Audit — Data Prep (TA*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TA*` (~14 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make every TA (data prep) template run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Stata 18 batch runs for `TA*` using fixtures; triage and fix all runtime errors.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to pipe-delimited `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent header blocks, indentation, macro naming, deterministic seeds.
- Defensive checks (Phase 4 level): validate required inputs early; produce structured `SS_RC` and explicit `warn/fail`.

## Out of scope

- Best-practice method upgrades beyond “runs + auditable diagnostics” (Phase 5).
- Placeholder/taxonomy redesign (earlier phases).

## Acceptance checklist

- [ ] Stata 18 baseline run: 0 `fail` across all `TA*` templates
- [ ] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [ ] Code style is normalized across `TA*`
- [ ] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

