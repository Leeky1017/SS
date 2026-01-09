# Phase 4.7: Template Code Quality Audit — Causal (TG*)

## Metadata

- Issue: #241
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `TG*` (~25 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make causal-inference templates run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style** (explicit handling for identification/data-shape failures).

## In scope

- Run Stata 18 harness for `TG*`; fix runtime errors and fragile assumptions.
- Defensive checks: treatment/control support, overlap/positivity signals, missingness, small samples; explicit `warn/fail`.
- Anchor format unification (锚点格式统一): standardize `SS_*` anchors to `SS_EVENT|k=v`.
- Code style unification (代码风格统一): consistent headers/steps/naming/seeds.

## Out of scope

- Best-practice causal method upgrades (e.g., alternative estimators, richer diagnostics) beyond “runs + auditable” (Phase 5).

## Acceptance checklist

- [x] Stata 18 baseline run: 0 `fail` across `TG*`
- [x] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [x] Identification/data-shape violations yield explicit `warn/fail` with `SS_RC`
- [x] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/249
- Summary:
  - Stata 18 smoke suite reached 0 fail for TG01–TG25 (fixtures)
  - Normalized legacy anchors (`SS_*:...`) to pipe-delimited anchors and `SS_RC`
  - Fixed fragile runtime paths in PSM/IV/RDD/DID templates and hardened fixtures
- Run log: `openspec/_ops/task_runs/ISSUE-241.md`
