# Proposal: issue-355-phase-4-15-bayes-ml-text-viz-tr-tu

## Why
Phase 4.15 requires reproducible Stata 18 evidence that Bayes/ML/text/viz templates (TR*–TU*) run with fixtures, emit contract-compliant anchors, and follow unified template style.

## What Changes
- Add a dedicated smoke-suite manifest for TR*–TU* scope (fixtures + minimal params + deps).
- Fix template runtime errors surfaced by the Stata 18 smoke-suite.
- Normalize template anchors from legacy `SS_*` variants to `SS_EVENT|k=v` (plus structured `SS_RC|...` for warnings/failures).
- Normalize template style (headers/steps/naming/seeds) within the scope.

## Impact
- Affected specs: `openspec/specs/ss-do-template-library/spec.md`, `openspec/specs/ss-do-template-optimization/spec.md`
- Affected code: `assets/stata_do_library/do/*.do`, `assets/stata_do_library/do/meta/*.meta.json`, `assets/stata_do_library/smoke_suite/*.json`
- Breaking change: NO (template behavior may become more defensive; anchor formats are standardized)
- User benefit: Stata 18 batch runs succeed (0 fail) with consistent, machine-parseable anchors and reproducible evidence reports.
