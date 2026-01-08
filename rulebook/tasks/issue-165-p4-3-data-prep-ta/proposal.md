# Proposal: issue-165-p4-3-data-prep-ta

## Why
Phase 4.3 requires TA01-TA14 to be runnable under the Stata 18 batch harness with fixtures, with consistent machine-parseable anchors and explicit fail-fast dependency checks.

## What Changes
- Extend `assets/stata_do_library/smoke_suite/manifest.1.0.json` and fixtures so TA01-TA14 can be executed by the smoke-suite harness.
- Normalize TA01-TA14 `.do` files: anchors (`SS_*|k=v`), dependency checks, input validation, deterministic seed where applicable, and fix discovered runtime errors.
- Record evidence in `openspec/_ops/task_runs/ISSUE-165.md`.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.3__data-prep-TA.md`
- Affected code: `assets/stata_do_library/do/TA01_*.do` … `TA14_*.do`, `assets/stata_do_library/smoke_suite/**`
- Breaking change: NO (template log anchor format within TA* becomes stricter; consumers should prefer pipe-delimited anchors)
- User benefit: Reliable, auditable data-prep template runs with deterministic behavior and clearer failure diagnostics.

