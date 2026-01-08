# Notes: issue-178-p52-core-t21-t50

## Template upgrade decisions (shared)

- Remove optional `estout/esttab` usage in `T21`–`T35` and replace with Stata 18-native report outputs (`putdocx` tables sourced from the same coefficient datasets already exported to CSV).
- Keep fail-fast behavior for required inputs (missing dataset, missing variables, invalid panel/time settings).
- Use `SS_RC|...|severity=warn` for expected non-fatal conditions (e.g., `log close` when no log is open, `mkdir` when directory already exists).

## Later (out of scope)

- Consider a shared “report export” include to reduce repetition across templates, but only if it does not complicate template portability.

