# SS do-template optimization — delta (ISSUE-280)

## Goal
- Audit `TK01`–`TK20` (Finance) templates for Stata 18 batch execution and anchor contract compliance.

## Requirements

### Requirement: TK01–TK20 SHALL be runnable under the Stata 18 smoke-suite harness
- For the scope `TK01`–`TK20`, the harness run SHALL report 0 `fail`.

### Requirement: TK anchors SHALL be normalized and machine-parseable
- Templates `TK01`–`TK20` SHALL emit contract-compliant `SS_EVENT|k=v` anchors.
- The header OUTPUTS section SHALL use `type=graph` (not `type=figure`).

### Requirement: Common finance failure modes MUST be explicit (warn/fail with SS_RC)
- Missing inputs/variables MUST fail fast with `SS_RC|...|severity=fail` and `SS_TASK_END|...|status=fail`.
- Non-fatal issues (e.g., graph export in batch mode) MUST emit `SS_RC|...|severity=warn` and continue when safe.

