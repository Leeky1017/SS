# Phase 4.9: Template Code Quality Audit — Survival + Multivariate (TI* + TJ*)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TI*` + `TJ*` (~17 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make survival and multivariate templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style**.

## In scope

- Run Stata 18 harness for `TI*` and `TJ*`; fix runtime errors.
- Defensive checks: survival time/censor encoding, `stset` requirements, small event counts, separation/non-convergence; explicit `warn/fail`.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Methodological upgrades (diagnostics, reporting, best-practice defaults) beyond “runs + auditable” (Phase 5).

## Acceptance checklist

- [ ] Stata 18 baseline run: 0 `fail` across `TI*` + `TJ*`
- [ ] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [ ] Common failure modes yield explicit `warn/fail` with `SS_RC` context
- [ ] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

