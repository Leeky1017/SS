# Proposal: issue-158-stata18-smoke-suite

## Why
Phase-4 requires auditing the full do-template library against real Stata 18 runs, but CI cannot reliably run Stata (license + environment). We need a reusable smoke-suite + evidence harness to run locally and a strong CI static gate to prevent regressions.

## What Changes
- Add a versioned smoke-suite manifest mapping `template_id → fixtures + minimal params + dependency notes`.
- Add a local CLI command to execute the smoke suite and write a structured JSON report (pass/fail/missing deps/outputs).
- Add CI-safe tests that validate the manifest and keep gates effective without Stata.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-3__stata18-smoke-suite.md`
- Affected code: `src/cli.py`, new smoke-suite modules, `assets/stata_do_library/`, `tests/`
- Breaking change: NO
- User benefit: reproducible Stata 18 execution evidence locally; CI still blocks manifest/contract drift when Stata is unavailable
