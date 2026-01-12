# Proposal: issue-420-output-formatter-coverage

## Why
Output formatter modules are user-facing deliverable logic (CSV/DTA conversions + structured error artifacts) but currently have low coverage, making regressions easy to miss.

## What Changes
- Add deterministic unit tests for formatter success and failure paths.
- Cover error artifact writing behavior (idempotent write, write failure handling).

## Impact
- Affected specs: none (task-scoped spec delta only)
- Affected code: `src/domain/output_formatter_data.py`, `src/domain/output_formatter_error.py`, new tests under `tests/`
- Breaking change: NO
- User benefit: Safer output formatting behavior and clearer error handling regressions.
