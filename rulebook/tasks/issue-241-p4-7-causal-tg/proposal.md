# Proposal: issue-241-p4-7-causal-tg

## Why
- TG01–TG25 are causal-inference templates and must run reliably on Stata 18 fixtures with contract-compliant anchors and explicit failure/warn signaling.

## What Changes
- Run the Stata 18 smoke-suite harness for TG01–TG25 and triage failures.
- Normalize legacy anchors (`SS_*:...`) to pipe-delimited `SS_EVENT|k=v` (including `SS_TASK_VERSION|version=...` and structured `SS_RC|...`).
- Harden common causal failure modes (missing deps, missing vars, overlap/common support, non-convergence) with explicit `warn/fail` + `SS_RC`.

## Impact
- Affected code: `assets/stata_do_library/do/TG*.do`, `assets/stata_do_library/fixtures/TG*/`, `assets/stata_do_library/smoke_suite/`, `openspec/_ops/task_runs/ISSUE-241.md`
- Breaking change: NO (template outputs/IDs unchanged; only runtime robustness + anchor format)
