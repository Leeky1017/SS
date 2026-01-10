# Proposal: issue-271-phase-4-9-survival-multivariate-ti-tj

## Why
- TI01–TI11 and TJ01–TJ06 are survival + multivariate templates and must run reliably on Stata 18 fixtures with contract-compliant anchors and explicit warn/fail signaling.

## What Changes
- Add a TI/TJ-scoped smoke-suite manifest (fixtures + params + dependency notes).
- Run the Stata 18 smoke-suite harness for TI01–TI11 and TJ01–TJ06 and triage failures.
- Normalize legacy anchors (`SS_*:...`) to pipe-delimited `SS_EVENT|k=v` per `assets/stata_do_library/SS_DO_CONTRACT.md`.
- Harden common failure modes (stset requirements, time/censor encoding, small event counts, separation/non-convergence) with explicit `warn/fail` + `SS_RC`.

## Impact
- Affected code: `assets/stata_do_library/do/TI*.do`, `assets/stata_do_library/do/TJ*.do`, `assets/stata_do_library/fixtures/`, `assets/stata_do_library/smoke_suite/`, `openspec/_ops/task_runs/ISSUE-271.md`
- Breaking change: NO (template IDs/outputs remain stable; only runtime robustness + anchor/style normalization)

