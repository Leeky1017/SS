# Phase 5.7: Template Content Enhancement — Causal (TG*)

## Metadata

- Issue: #258
- Parent: #125
- Superphase: Phase 5 (content enhancement)
- Templates: `TG*` (~25 templates, current inventory)
- Depends on:
  - Phase 4.7 (runtime errors fixed; anchors/style standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enhance causal templates with best practices (最佳实践), Stata 18-native tooling (替换 SSC), stronger error handling, and bilingual comments (中英文注释).

## In scope

- Best-practice upgrades: clear identification assumptions and minimal method-appropriate diagnostics outputs.
- Replace SSC dependencies with Stata 18 native equivalents where feasible; justify exceptions.
- Error handling enhancements: support/overlap checks, weak identification signals, and explicit `warn/fail` policy.
- Bilingual comments (中英文注释) for key steps and interpretation notes.

## Out of scope

- Introducing new SSC dependencies without an explicit allowlist decision.
- Taxonomy/index changes and placeholder redesign.

## Acceptance checklist

- [x] Each `TG*` template has a best-practice review record
- [x] SSC deps removed/replaced where feasible (exceptions justified)
- [x] Error handling and diagnostics are strengthened (no silent failure)
- [x] Key steps have bilingual comments (中英文注释)
- [x] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-258.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/265
- TG01–TG25: best-practice review blocks + bilingual notes + version bump to 2.1.0
- PSM/IV/TWFE: replaced SSC with Stata-native where feasible; SSC-only methods kept with explicit deps
- Index + smoke-suite manifests aligned to updated TG meta
- Run log: `openspec/_ops/task_runs/ISSUE-258.md`
