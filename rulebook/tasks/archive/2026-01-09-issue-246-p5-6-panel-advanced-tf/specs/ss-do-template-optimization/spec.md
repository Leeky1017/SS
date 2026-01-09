# Delta Spec: Phase 5.6 — Panel Advanced (TF*)

## Scope
- Templates: `TF01`–`TF14` (current inventory)
- Changes: best-practice review records + bilingual comments + improved error handling + SSC dependency evaluation/replacement.

## Requirements (delta)

### Requirement: Each TF template contains a best-practice review record
- Each `TF*` template MUST include a Phase 5.6 review block:
  - comment header: `PHASE 5.6 REVIEW (Issue #246) / 最佳实践审查（阶段 5.6）`
  - a structured anchor line: `SS_BP_REVIEW|issue=246|template_id=TF..|ssc=...|output=...|policy=...`

### Requirement: SSC dependencies are replaced where feasible
- If a Stata 18 built-in alternative exists (or a safe built-in fallback is acceptable), the template MUST prefer built-in commands by default.
- If an SSC dependency remains, the template MUST:
  - declare it explicitly via `SS_DEP_CHECK|...` and
  - include a brief rationale in bilingual comments in the review block.

### Requirement: Error handling is explicit and non-silent
- Templates MUST fail fast on:
  - missing required inputs
  - failed `xtset`
- Templates MUST warn (not fail) on:
  - small samples / likely weak within variation signals

## Scenarios (spot-check)
- Missing panel/time vars → structured `SS_RC` fail with non-zero exit code.
- Missing optional SSC package (when fallback exists) → `SS_RC` warn and continue with fallback estimation.
