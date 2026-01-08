# Proposal: issue-192-p5-5-regression-td-te

## Why
Phase 5.5 upgrades TD* (linear regression) and TE* (limited dependent variable) templates to reduce environment fragility (SSC table exporters), clarify model assumptions, and harden failure modes (collinearity, separation, non-convergence) for auditable automated runs.

## What Changes
- Add per-template best-practice review records and bilingual comments (中英文注释) for key steps + interpretation hints.
- Replace SSC dependencies where feasible (notably `estout/esttab` and `twopm`; and `reghdfe` for the TD01 case where base-Stata `xtreg, fe` is acceptable).
- Strengthen validation and error handling for regression edge cases and emit explicit `SS_RC|...` diagnostics.
- Align affected template `meta.json` dependencies with implemented behavior.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-5.5__regression-TD-TE.md`
- Affected code: `assets/stata_do_library/do/TD01_*.do` … `TD12_*.do`, `assets/stata_do_library/do/TE01_*.do` … `TE10_*.do`, related `assets/stata_do_library/do/meta/*.meta.json`
- Breaking change: NO (template IDs/files unchanged; outputs remain declared)
- User benefit: More reliable regression runs with clearer diagnostics and fewer external dependency failures.

