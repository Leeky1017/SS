# Phase 4.12: Template Code Quality Audit — Medical / Biostats (TM*)

## Metadata

- Issue: #273
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TM*` (~15 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make medical/biostats templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for `TM*`; fix runtime errors.
- Defensive checks: small samples, separation/non-convergence (as applicable), missingness; explicit `warn/fail`.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Best-practice method upgrades and richer diagnostics outputs (Phase 5).

## Acceptance checklist

- [ ] Stata 18 baseline run: 0 `fail` across `TM*`
- [ ] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [ ] Common failure modes yield explicit `warn/fail` with `SS_RC` context
- [ ] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`
