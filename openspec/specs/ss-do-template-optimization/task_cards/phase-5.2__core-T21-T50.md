# Phase 5.2: Template Content Enhancement — Core (T21–T50)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `T21`–`T50` (30 templates, current inventory)
- Depends on:
  - Phase 4.2 (runtime errors fixed; anchors/style standardized)
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

- [ ] Each template has a best-practice review record (what changed + why)
- [ ] SSC deps are removed/replaced where feasible (exceptions justified)
- [ ] Error handling is stronger with explicit `warn/fail` and `SS_RC` context
- [ ] Key steps have bilingual comments (中英文注释)
- [ ] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

