# Proposal: issue-521-be-006-auxiliary-column-candidates

## Why
Draft preview only exposes primary dataset columns, so users cannot select variables from auxiliary files and the panel workflow cannot be completed.

## What Changes
- Extend draft preview enrichment to include columns from all uploaded datasets (primary + auxiliary).
- Keep existing `column_candidates: list[str]` for backward compatibility.
- Add `column_candidates_v2` with dataset source info for grouping and disambiguation.

## Impact
- Affected specs: `openspec/specs/ss-ux-remediation/task_cards/BE-006__auxiliary-column-candidates.md`
- Affected code: `src/domain/draft_inputs_introspection.py`, `src/domain/models.py`, `src/api/schemas.py`, `src/api/draft.py`
- Breaking change: YES/NO
- Breaking change: NO
- User benefit: variable selection UI can include auxiliary columns and avoid same-name ambiguity.
