# Notes: issue-494-e2e-boundary-coverage

## Decisions
- (pending) Hidden-sheet strategy: prefer “visible-only” in `sheet_names` unless product decides otherwise.
- (pending) Formula preview: assert current behavior (cached values vs raw formula) and document it in coverage.

## Open questions
- Should “huge dataset” return a stable `413` size limit at upload time, or a `400`/`422` at preview time?
- Should `STATA_TIMEOUT`/`STATA_NONZERO_EXIT` be considered non-retriable by default for deterministic failures?

## Later
- Add a dedicated E2E dataset corpus under `tests/fixtures/` once baseline edge cases are stable.

