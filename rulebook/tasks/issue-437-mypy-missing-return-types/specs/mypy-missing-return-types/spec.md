# Spec: mypy missing return types

## Goal
Eliminate all `missing return type` errors from `mypy src/ --strict`.

## Requirements
- All functions in `src/` that are flagged by mypy for `missing return type` must have an explicit return type annotation.
- The change must be type-only (no intentional runtime behavior changes).
- `mypy src/ --strict` must pass.
- `pytest -q` must pass.

## Scenarios
- When running `mypy src/ --strict`, there are no `missing return type` errors.
