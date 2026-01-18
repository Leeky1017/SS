# Proposal: issue-527-be-008-id-time-var-selection

## Why
Panel templates require `__ID_VAR__` and `__TIME_VAR__` (or aliases), but there is no backend contract/UI path to supply them during plan freeze, causing `PLAN_FREEZE_MISSING_REQUIRED`.

## What Changes
- Add `required_variables` to draft preview so the frontend can render ID/TIME selectors.
- Allow plan freeze to accept selected values and populate required template params.

## Impact
- Affected specs: `openspec/specs/ss-ux-remediation/task_cards/BE-008__id-time-var-selection.md`
- Affected code: `src/api/schemas.py`, `src/api/draft.py`, `src/api/jobs.py`, `src/domain/do_template_plan_support.py`
- Breaking change: YES/NO
- Breaking change: NO
- User benefit: missing-required path becomes actionable and can be resolved by selecting variables.
