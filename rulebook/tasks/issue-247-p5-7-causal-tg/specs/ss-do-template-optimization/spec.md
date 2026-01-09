# Delta Spec: Phase 5.7 — Causal (TG*)

## Scope
- Templates: `TG01`–`TG25` (current inventory)
- Changes: best-practice review records + bilingual comments + improved error handling + SSC dependency evaluation/replacement.

## Requirements (delta)

### Requirement: Each TG template contains a best-practice review record
- Each `TG*` template MUST include a Phase 5.7 review block:
  - comment header: `PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）`
  - a structured anchor line: `SS_BP_REVIEW|issue=247|template_id=TG..|ssc=...|output=...|policy=...`

### Requirement: Prefer Stata 18 native causal tooling where feasible
- PSM templates SHOULD prefer `teffects` + `tebalance` over `psmatch2` when feasible.
- IV templates SHOULD prefer `ivregress` + `estat firststage/overid` over `ivreg2/ranktest` when feasible.
- DID templates SHOULD prefer `didregress/xtdidregress` where feasible; parallel-trend checks MUST be explicit.

### Requirement: Explicit error and warning policy
- Templates MUST fail fast on:
  - missing required inputs / variables
  - degenerate support (no treated or no control; no overlap)
- Templates MUST warn (not fail) on:
  - weak-IV signals (e.g., low first-stage F) with explicit guidance in bilingual comments.

## Scenarios (spot-check)
- Missing treatment var → structured `SS_RC` fail.
- Weak first-stage → `SS_RC` warn and continue (estimation still runs).
