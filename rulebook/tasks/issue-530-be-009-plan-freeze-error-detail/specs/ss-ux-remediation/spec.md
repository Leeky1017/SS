# Spec Delta: BE-009 Plan freeze error detail

## Requirement: `PLAN_FREEZE_MISSING_REQUIRED` is actionable

When plan freeze fails due to missing required inputs, the API MUST return a structured error payload that is directly usable to render a completion UI.

The response MUST remain backward compatible with existing clients by keeping:
- `missing_fields: list[str]`
- `missing_params: list[str]`
- `next_actions: list[...]`

The response MUST add (non-breaking) enhancement fields:
- `missing_fields_detail: [{ field: str, description: str, candidates: list[str] }]`
- `missing_params_detail: [{ param: str, description: str, candidates: list[str] }]`
- `action: str`

Each `next_actions` item SHOULD include `type`, `label`, and `payload_schema` for UI rendering.

#### Scenario: Plan freeze missing required returns details
- **GIVEN** a job where plan freeze is blocked by missing required fields/params
- **WHEN** `POST /v1/jobs/{job_id}/plan/freeze` is called
- **THEN** response is `400` with `{"error_code":"PLAN_FREEZE_MISSING_REQUIRED","message":"..."}` and includes the detail fields above
