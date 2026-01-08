# Phase 5.1: Template Content Enhancement — Core (T01–T20)

## Metadata

- Issue: #193
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `T01`–`T20` (20 templates, current inventory)
- Depends on:
  - Phase 4.1 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Upgrade templates in scope from “can run” to **production-grade analysis**: best practices, Stata 18-native tooling (减少 SSC 依赖), stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice method upgrades (最佳实践方法升级) with an explicit decision record per template.
- Replace SSC dependencies with Stata 18 native equivalents where feasible (SSC 依赖替换为 Stata 18 原生); otherwise document exceptions explicitly.
- Error handling enhancements (错误处理增强): systematic input checks + explicit `warn/fail` policy (no silent failure).
- Bilingual comments (中英文注释) for key steps and assumptions; keep anchors structured and machine-readable.
- Output upgrades where appropriate: prefer Stata 18 `collect` / `etable` / `putexcel` / `putdocx` over SSC table tooling.

## Out of scope

- New SSC dependencies without an explicit allowlist decision and audit trail.
- Taxonomy/index redesign (Phases 0–2).

## Acceptance checklist

- [x] Each template has a best-practice review record (what changed + why)
- [x] SSC deps are removed/replaced where feasible (exceptions justified)
- [x] Error handling is stronger with explicit `warn/fail` and `SS_RC` context
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/196
- Summary:
  - Added per-template Phase 5.1 best-practice review records + bilingual step comments for T01–T20.
  - Removed SSC dependency `estout/esttab` from core (T19/T20) by switching to Stata 18 native `putdocx`.
  - Updated meta + smoke-suite manifest dependency declarations to keep validation/tests consistent.
- Run log: `openspec/_ops/task_runs/ISSUE-193.md`
