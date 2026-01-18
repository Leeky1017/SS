# Proposal: issue-530-be-009-plan-freeze-error-detail

## Why
`PLAN_FREEZE_MISSING_REQUIRED` currently exposes only `missing_fields`/`missing_params` string lists, which are not sufficient for a UI to guide users to complete missing items (no descriptions/candidates/action). This blocks FE-043 from rendering an actionable “fix and retry” flow.

## What Changes
- Keep existing fields (`missing_fields`, `missing_params`, `next_actions`) compatible.
- Add optional detail fields to the error payload:
  - `missing_fields_detail: [{ field, description, candidates }]`
  - `missing_params_detail: [{ param, description, candidates }]`
  - `action: string` (user-facing guidance)
- Enrich `next_actions` items with `type`, `label`, and `payload_schema` for direct UI rendering.

## Impact
- Affected specs: `openspec/specs/ss-ux-remediation/task_cards/BE-009__plan-freeze-error-detail.md`
- Affected code: `src/domain/*` (plan freeze gate), `src/infra/plan_exceptions.py`
- Breaking change: NO
- User benefit: users can complete missing inputs via guided UI and retry plan freeze successfully
