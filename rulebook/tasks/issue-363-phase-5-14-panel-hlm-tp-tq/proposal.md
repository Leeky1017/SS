# Proposal: issue-363-phase-5-14-panel-hlm-tp-tq

## Why
- TP01–TP15 + TQ01–TQ12 cover core panel/time-series/HLM workflows; Phase 5 requires best-practice upgrades, fewer SSC dependencies, and clearer failure modes to improve Stata 18 reproducibility.

## What Changes
- Add per-template Phase 5.14 best-practice review records + bilingual comments (中英文注释).
- Strengthen panel/tsset/mixed preflight checks and explicit warn/fail error handling (no silent failure).
- Replace SSC dependencies with Stata 18 native alternatives where feasible; otherwise keep explicit checks + justification.

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5.14__panel-hlm-TP-TQ.md`
- Affected code:
  - `assets/stata_do_library/do/TP*.do`
  - `assets/stata_do_library/do/TQ*.do`
- Breaking change: NO
- User benefit: more robust defaults + better diagnostics and fewer environment/setup surprises.
