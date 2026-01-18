# Proposal: issue-523-be-007-column-name-normalization

## Why
Chinese (and other non-Stata-safe) column names need a stable, traceable normalization so generated plans/do-files can reliably reference variables.

## What Changes
- Add a deterministic column normalization utility producing Stata-safe names.
- Expose `original -> normalized` mapping in draft preview for UI confirmation.

## Impact
- Affected specs: `openspec/specs/ss-ux-remediation/task_cards/BE-007__column-name-normalization.md`
- Affected code: `src/domain/column_normalizer.py`, `src/domain/draft_service.py`, `src/api/schemas.py`, `src/api/draft.py`
- Breaking change: YES/NO
- Breaking change: NO
- User benefit: users can see/confirm how variables will be referenced in Stata.
