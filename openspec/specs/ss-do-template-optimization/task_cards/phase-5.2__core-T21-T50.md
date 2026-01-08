# Phase 5.2: Template Content Enhancement — Core (T21–T50)

## Metadata

- Issue: #178
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

- [x] Each template has a best-practice review record (what changed + why)
- [x] SSC deps are removed/replaced where feasible (exceptions justified)
- [x] Error handling is stronger with explicit `warn/fail` and `SS_RC` context
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-178.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/184
- Run log: `openspec/_ops/task_runs/ISSUE-178.md`
- Summary:
  - Added `BEST_PRACTICE_REVIEW` records and bumped template versions to `2.1.0` for `T21`–`T50`.
  - Removed optional SSC `estout/esttab` outputs in `T21`–`T24` and `T31`–`T35` and replaced with Stata 18 `putdocx` reports (meta outputs updated to `.docx`).
  - Strengthened input validation and error handling (robust VCE for discrete/count models; correct factor-variable interaction for `T21` margins; warn-level `SS_RC` for expected non-fatal conditions).
