# Phase 4.1: Template Code Quality Audit — Core (T01–T20)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 4 (full-library Stata 18 audit)
- Templates: `T01`–`T20` (20 templates, current inventory)
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make every template in scope run on **Stata 18** with fixtures, emit **contract-compliant anchors**, and follow **unified style** (no runtime errors, no silent failures).

## In scope

- Run Stata 18 batch harness for all templates in scope using their fixtures.
- Runtime error fixes (运行时错误修复): missing files/vars, type mismatches, empty samples, convergence/collinearity cases with explicit `warn/fail`.
- Anchor format unification (锚点格式统一): normalize all `SS_*` anchors to pipe-delimited `SS_EVENT|k=v` format (remove legacy `SS_*:...` variants).
- Code style unification (代码风格统一): header blocks, indentation, macro naming, deterministic randomness (`set seed ...`), consistent `SS_STEP_BEGIN/END`.
- Dependency handling: detect missing SSC packages (where applicable) and fail fast with structured `SS_RC` + context.

## Out of scope

- Methodological upgrades / best-practice redesigns (Phase 5).
- Taxonomy/index changes (Phases 0–2).

## Acceptance checklist

- [ ] Stata 18 baseline run: 0 `fail` across all templates in scope (fixtures)
- [ ] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [ ] Code style is normalized across the scope (headers/steps/naming/seeds)
- [ ] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

