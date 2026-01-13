# Proposal: issue-437-mypy-missing-return-types

## Why
`mypy src/ --strict` currently reports `missing return type` errors, which blocks strict type checking and reduces maintainability.

## What Changes
- Add explicit return type annotations to all functions in `src/` currently reported by mypy as missing a return type.
- Keep behavior unchanged (type-only changes).

## Impact
- Affected specs: none (type annotations only)
- Affected code: `src/**.py` (functions with missing return types)
- Breaking change: NO
- User benefit: strict mypy passes; clearer contracts; easier refactors
