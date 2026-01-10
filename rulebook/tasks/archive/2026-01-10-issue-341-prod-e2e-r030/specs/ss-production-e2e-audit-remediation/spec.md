# Spec delta: ss-production-e2e-audit-remediation (issue-341-prod-e2e-r030)

## Requirement: Plan freeze rejects missing required inputs with structured errors

Plan freeze MUST fail with a structured error when either:
- v1 draft blockers exist (missing stage question answers and/or blocking open_unknowns), or
- required template parameters (from do-template meta parameter specs) are missing.

#### Scenario: Missing inputs are rejected at plan freeze
- **GIVEN** a job in `draft_ready` state
- **WHEN** calling `POST /v1/jobs/{job_id}/plan/freeze` with missing blockers/params
- **THEN** it fails with a structured error payload including:
  - `error_code` from a fixed set
  - `missing_fields` and/or `missing_params`
  - `next_actions` describing how to correct and retry

