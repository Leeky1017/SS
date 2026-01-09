# Proposal: issue-240-panel-advanced-tf01-tf14

## Why
Phase 4 requires Stata 18 runtime evidence and a “0 fail” baseline for the template library. The TF* (panel advanced) templates still contain legacy `SS_*:<...>` anchors and fragile runtime paths (deps/panel preconditions) that block auditable smoke-suite runs.

## What Changes
- Run TF01–TF14 via the Stata 18 smoke-suite harness using fixtures.
- Fix template runtime errors and tighten panel precondition handling with explicit `SS_RC|...|severity=warn|fail` anchors.
- Normalize anchors within scope to pipe-delimited `SS_EVENT|k=v` per `assets/stata_do_library/SS_DO_CONTRACT.md` (remove legacy `SS_*:<...>` variants).
- Record evidence in `openspec/_ops/task_runs/ISSUE-240.md`.

## Impact
- Affected specs:
  - `assets/stata_do_library/SS_DO_CONTRACT.md` (no spec change; follow existing contract)
  - Task cards:
    - `openspec/specs/ss-do-template-optimization/task_cards/phase-4.6__panel-advanced-TF.md`
- Affected code:
  - `assets/stata_do_library/do/TF*.do`
  - `assets/stata_do_library/do/includes/ss_smart_xtset.ado` (anchor compliance when used by TF templates)
  - `assets/stata_do_library/fixtures/TF*/`
  - `assets/stata_do_library/smoke_suite/*.json` (new manifest for this scope)
- Breaking change: NO (template contract tightened within existing v1.1 semantics)
- User benefit: reproducible Stata 18 runs with consistent, machine-parseable anchors and clearer diagnostics for common panel failures.

