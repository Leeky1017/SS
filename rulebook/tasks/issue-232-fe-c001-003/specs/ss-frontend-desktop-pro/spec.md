# Spec Delta: issue-232-fe-c001-003 (ss-frontend-desktop-pro)

## References (canonical)
- `openspec/specs/ss-frontend-desktop-pro/spec.md`
- `openspec/specs/ss-frontend-desktop-pro/task_cards/round-03-fe-a__FE-C001.md`
- `openspec/specs/ss-frontend-desktop-pro/task_cards/round-03-fe-a__FE-C002.md`
- `openspec/specs/ss-frontend-desktop-pro/task_cards/round-03-fe-a__FE-C003.md`

## Delta Requirements

### Requirement: Dev default can run without backend (explicit, non-production)
In local development, the frontend MAY provide a mock response path for Step 1 to allow UI iteration without a running backend.

This MUST be:
- explicitly marked as dev-only (e.g., only enabled in `import.meta.env.DEV`), and
- never used as the default production behavior.

### Requirement: Fallback-to-jobs remains gated by `VITE_REQUIRE_TASK_CODE`
`VITE_REQUIRE_TASK_CODE=1` MUST disable the dev-only fallback-to-`POST /v1/jobs` path, matching the canonical spec.

## Scenarios

### Scenario: Dev mock enables standalone UI iteration
- **GIVEN** `import.meta.env.DEV` and mock mode enabled
- **WHEN** the user submits Step 1
- **THEN** the UI proceeds with a mocked `{job_id, token}` and persists `ss.last_job_id` + `ss.auth.v1.{job_id}`
