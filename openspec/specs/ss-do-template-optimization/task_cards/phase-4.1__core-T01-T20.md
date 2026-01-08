# Phase 4.1: Template Code Quality Audit — Core (T01–T20)

## Metadata

- Issue: #163
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

- [x] Stata 18 baseline run: 0 `fail` across all templates in scope (fixtures)
- [x] Anchors are contract-compliant and consistent (`SS_EVENT|k=v`)
- [x] Code style is normalized across the scope (headers/steps/naming/seeds)
- [x] Evidence + per-template reports are linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/189
- Summary:
  - Normalized T01–T20 anchors to `SS_EVENT|k=v` (+ `SS_TASK_VERSION|version=2.0.1`) and unified style (headers/steps/naming/seeds).
  - Added SSC dependency fast-fail paths where applicable (e.g. `estout`) with structured anchors (`SS_DEP_MISSING|pkg=...`, `SS_RC|code=199|...`).
  - Added a dedicated smoke-suite manifest for Phase 4.1 core T01–T20 and recorded the batch run results.
- Run log: `openspec/_ops/task_runs/ISSUE-163.md`
