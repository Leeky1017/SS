# Phase 5: Template Content Enhancement (Best Practices + Diagnostics + Outputs)

## Metadata

- Issue: TBD
- Parent: #125
- Depends on:
  - Phase 4 full-library code-quality pass (no runtime errors, anchors standardized)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Upgrade the template library from “can run” to **production-grade analysis** by applying modern Stata 18 best practices, stronger defensive checks, and clearer deliverables (tables/figures/reports), while keeping behavior auditable and maintainable.

## In scope

- Method review (template-by-template, with an explicit decision record):
  - identify outdated or fragile methods and replace with best-practice alternatives
  - clarify default inference choices (robust/cluster/HAC, FE strategy, small-sample corrections where relevant)
  - document assumptions + applicability in `SS_SUMMARY` lines and meta tags/keywords
- Defensive robustness upgrades:
  - systematic input checks (missingness, type, support/overlap, sample size, extreme weights, separation, convergence)
  - explicit `warn/fail` policy with `SS_RC` + summary diagnostics (no silent failures)
- Diagnostics (minimal, method-appropriate):
  - regression: residual + influence diagnostics; heteroskedasticity checks where applicable
  - panel: serial correlation / cross-sectional dependence options; FE/cluster clarity
  - time series: stationarity + residual whiteness checks; lag/VAR order selection evidence
  - limited dependent variables: separation/fit diagnostics; marginal effects outputs
  - causal methods: balance checks; parallel-trend evidence; weak-IV diagnostics; sensitivity hooks where feasible
- Output standardization (library-wide):
  - consistent naming + file types for tables/figures/reports
  - professional tables (Stata 18 `collect` / `etable` / `putexcel` / `putdocx` where appropriate)
  - clearer plots (titles/labels/notes) and exported formats (`png` + optional `pdf`)
- Capability gap analysis:
  - identify important empirical capabilities not covered by current templates
  - propose new template candidates (with scope, minimal contract, dependencies, fixtures)

## Out of scope

- Replacing the selection/index/taxonomy protocol (handled in earlier phases).
- Turning templates into a general workflow engine (composition stays explicit/minimal).
- Adding new SSC dependencies without an explicit allowlist decision and audit trail.

## Acceptance checklist

- [ ] Each template family has a best-practice review record (what changed + why + Stata 18 references)
- [ ] High-impact templates are upgraded with stronger error handling + method-appropriate diagnostics
- [ ] Outputs are standardized (tables/figures/reports) and are consistent across the library
- [ ] Capability gap list is produced with prioritized “new template” proposals (and links to follow-up task cards/issues)
- [ ] Implementation run log (`openspec/_ops/task_runs/ISSUE-<N>.md`) includes evidence for upgraded templates (before/after runs + key outputs)
