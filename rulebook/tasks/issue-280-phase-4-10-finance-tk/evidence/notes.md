# Notes — ISSUE-280 (Finance TK01–TK20)

## Findings
- TK01–TK20 can pass Stata 18 smoke suite with official commands only; common failure modes were missing SSC commands, `xtset` assumptions, and graph/export edge cases in batch mode.
- Templates previously mixed legacy anchors (`SS_*:` / `SS_WARNING:` / `SS_ERROR:`) with pipe-delimited anchors; unified to `SS_EVENT|k=v` for machine parsing.

## Decisions
- Use per-template `ss_fail_TKxx` to centralize fail-fast behavior (`SS_RC|...|severity=fail` + `SS_TASK_END|...|status=fail`) and remove duplicated legacy error anchors.
- Standardize graph outputs to `type=graph` (header OUTPUTS + `SS_OUTPUT_FILE`).

## Later
- (optional follow-ups; keep out of current PR scope)
