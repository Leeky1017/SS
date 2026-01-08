# Proposal: issue-172-p44-p45-tb-tc-td-te-audit

## Why
Phase 4 requires Stata 18 runtime evidence and “0 fail” baseline for the template library. TB/TC (descriptive + tests) and TD/TE (regression + special models) still emit legacy `SS_*:<...>` anchors and contain fragile runtime paths (deps, convergence/collinearity) that block auditable smoke-suite runs.

## What Changes
- Run TB02–TB10, TC01–TC10, TD01–TD06 + TD10 + TD12, TE01–TE10 with the Stata 18 smoke-suite harness using fixtures.
- Fix template runtime errors and tighten regression failure-mode handling with explicit `SS_RC|...|severity=warn|fail` anchors.
- Normalize anchors within scope to pipe-delimited `SS_*|k=v` per `assets/stata_do_library/SS_DO_CONTRACT.md` (remove legacy `SS_*:<...>` variants).
- Record evidence in `openspec/_ops/task_runs/ISSUE-172.md`.

## Impact
- Affected specs:
  - `assets/stata_do_library/SS_DO_CONTRACT.md` (no spec change; follow existing contract)
  - Task cards:
    - `openspec/specs/ss-do-template-optimization/task_cards/phase-4.4__descriptive-TB-TC.md`
    - `openspec/specs/ss-do-template-optimization/task_cards/phase-4.5__regression-TD-TE.md`
- Affected code:
  - `assets/stata_do_library/do/TB*.do`
  - `assets/stata_do_library/do/TC*.do`
  - `assets/stata_do_library/do/TD*.do`
  - `assets/stata_do_library/do/TE*.do`
  - `assets/stata_do_library/smoke_suite/*.json` (new manifest for this scope)
- Breaking change: YES/NO
- Breaking change: NO (template contract tightened within existing v1.1 semantics)
- User benefit: reproducible Stata 18 runs with consistent, machine-parseable anchors and clearer diagnostics for common regression failures.
