# Delta Spec: Phase 5.14 — Panel + HLM (TP* + TQ*)

## Scope
- Templates: `TP01`–`TP15` + `TQ01`–`TQ12` (current inventory)
- Changes: best-practice review records + bilingual comments + improved error handling + SSC dependency evaluation/replacement.

## Requirements (delta)

### Requirement: Each TP/TQ template contains a best-practice review record
- Each `TP*` / `TQ*` template MUST include a Phase 5.14 review block:
  - comment header: `PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）`
  - a structured anchor line: `SS_BP_REVIEW|issue=363|template_id=TP..|ssc=...|output=...|policy=...`

### Requirement: SSC dependencies are replaced where feasible
- If a Stata 18 built-in alternative exists (or a safe built-in fallback is acceptable), the template MUST prefer built-in commands by default.
- If an SSC dependency remains, the template MUST:
  - declare it explicitly via `SS_DEP_CHECK|...` and
  - include a brief rationale in bilingual comments in the review block.

### Requirement: Error handling is explicit and non-silent
- Templates MUST fail fast on:
  - missing required inputs
  - failed `xtset`/`tsset`/`svyset`/`mixed` estimation
- Templates MUST warn (not fail) on:
  - small samples / weak identification signals
  - likely data-shape issues that do not block estimation (e.g., singleton groups)

## Scenarios (spot-check)
- Missing required variables → structured `SS_RC` fail with non-zero exit code.
- Missing SSC dependency → fail if required; warn + fallback only when a built-in fallback exists.

