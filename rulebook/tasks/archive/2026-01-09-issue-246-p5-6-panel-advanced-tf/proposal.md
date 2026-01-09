# Proposal: issue-246-p5-6-panel-advanced-tf

## Why
- TF01–TF14 are “advanced panel” templates; Phase 5 requires best-practice content upgrades and SSC dependency reduction to improve reproducibility on Stata 18.

## What Changes
- Add per-template Phase 5.6 best-practice review records + bilingual comments (中英文注释).
- Strengthen panel structure checks and error handling (xtset, singleton groups, weak within variation).
- Replace SSC dependencies with Stata 18 native alternatives where feasible; otherwise provide explicit checks + justification.

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5.6__panel-advanced-TF.md`
- Affected code:
  - `assets/stata_do_library/do/TF*.do`
  - `assets/stata_do_library/do/meta/TF*.meta.json`
  - `assets/stata_do_library/smoke_suite/manifest.issue-240.tf01-tf14.1.0.json` (if deps change)
- Breaking change: YES/NO
- User benefit: more robust panel diagnostics defaults + clearer failure modes; fewer SSC requirements.
