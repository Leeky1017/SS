# Proposal: issue-247-p5-7-causal-tg

## Why
- TG01–TG25 cover core causal workflows; Phase 5 requires best-practice upgrades and SSC dependency reduction to improve reproducibility and interpretability.

## What Changes
- Add per-template Phase 5.7 best-practice review records + bilingual comments (中英文注释).
- Replace SSC commands with Stata 18 native alternatives where feasible (PSM/IV/DID).
- Strengthen error handling for identification-critical failures (support/overlap, weak identification warnings).

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5.7__causal-TG.md`
- Affected code:
  - `assets/stata_do_library/do/TG*.do`
  - `assets/stata_do_library/do/meta/TG*.meta.json`
  - `assets/stata_do_library/smoke_suite/manifest.*.tg*.json` (if deps change)
- Breaking change: YES/NO
- User benefit: fewer SSC requirements by default; clearer diagnostics and failure modes for causal identification.
