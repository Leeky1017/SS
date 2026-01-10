# Spec Delta: PROD-E2E-R020 — Dependency diagnostics + retry (ado/SSC)

## Requirement: Missing declared Stata dependencies are diagnosable

- **GIVEN** a frozen plan whose selected template meta declares SSC/ado dependencies
- **WHEN** the worker is about to run the job
- **AND** some dependencies are missing from the Stata environment
- **THEN** the run attempt MUST fail before execution with:
  - `error_code: STATA_DEPENDENCY_MISSING`
  - `details.missing_dependencies[]` containing the missing dependency identifiers
- **AND** the worker MUST archive the structured error in `run.error.json` for audit/repro.

## Requirement: Failed jobs are retryable after environment fix

- **GIVEN** a job in `failed` due to missing Stata dependencies
- **WHEN** operators fix the environment (e.g. install SSC packages via image/ops)
- **AND** the client calls `POST /v1/jobs/{job_id}/run`
- **THEN** SS MUST re-queue the same job for another run attempt and succeed if the environment is now valid.

## Non-goal

- SS MUST NOT auto-install SSC packages at runtime.

