# Phase 4: Template Code Quality Audit (Stata 18, Full Library)

## Metadata

- Issue: TBD
- Parent: #125
- Depends on:
  - Phase 3 smoke suite + evidence harness
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Ensure **every** template in `assets/stata_do_library/do/*.do` can run on **Stata 18** with fixtures and produces contract-compliant artifacts (logs/outputs/anchors) without runtime errors.

## In scope

- Batch-run the full template inventory (N = derived from canonical meta/index at runtime; no hardcoded counts).
- Use fixture data per template (existing `assets/stata_do_library/fixtures/<template_id>/`) and a deterministic parameter map:
  - required placeholders are always filled (or the template fails with a structured, auditable error).
  - randomness is deterministic (`set seed ...` + `SS_METRIC|name=seed|...` where applicable).
- Collect a structured execution report for each template:
  - status: `ok` / `warn` / `fail`
  - Stata exit code, elapsed time, key `SS_RC` lines, missing dependency signals, output file list
  - parse + validate `SS_*` anchors against the contract (pipe-delimited `SS_EVENT|k=v` format).
- Fix all runtime errors found by the batch runner:
  - input validation (missing file/vars, type mismatches, sample too small)
  - dependency detection + fail-fast on missing SSC packages (where allowed)
  - convergence / collinearity / perfect prediction common failure modes handled with explicit `warn/fail`
  - remove/replace unsafe commands and hardcoded paths
- Normalize code style across the library:
  - header block formatting, indentation, consistent local macro naming
  - consistent step boundaries (`SS_STEP_BEGIN/END`) and metrics/summaries
  - fix legacy/inconsistent anchor formats (e.g., `SS_METRIC:n_input:` → `SS_METRIC|name=n_input|value=...`)
- Evidence discipline:
  - store per-template logs + rendered do-file + parameter map
  - include batch summary + top failure reasons in `openspec/_ops/task_runs/ISSUE-<N>.md`

## Out of scope

- Methodological upgrades (best-practice statistical improvements) beyond correctness/robust execution (Phase 5).
- Taxonomy/placeholder redesign beyond earlier phases.
- Running Stata in CI if licensing/environment blocks it (batch runner may be “local-only”).

## Acceptance checklist

- [ ] Batch runner executes 100% of templates (inventory derived at runtime) on Stata 18 using fixtures
- [ ] A machine-readable report is produced (JSON + CSV summary) with per-template status + error taxonomy
- [ ] Zero templates end in `fail` for the “baseline fixture” run (or an explicit allowlist with justification exists)
- [ ] All templates emit contract-compliant `SS_*` anchors and declare outputs consistently
- [ ] Code style is normalized and anchor format is consistent across the library
- [ ] Implementation run log (`openspec/_ops/task_runs/ISSUE-<N>.md`) contains the exact commands + key outputs + report paths
