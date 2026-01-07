# Phase 5.7: Template Content Enhancement — Causal (TG*)

## Metadata

- Issue: TBD
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

- [ ] Each `TG*` template has a best-practice review record
- [ ] SSC deps removed/replaced where feasible (exceptions justified)
- [ ] Error handling and diagnostics are strengthened (no silent failure)
- [ ] Key steps have bilingual comments (中英文注释)
- [ ] Evidence (runs + outputs) is linked from `openspec/_ops/task_runs/ISSUE-<N>.md`

