# Tasks: PROD-E2E-R020

- Add `STATA_DEPENDENCY_MISSING` structured error with missing list in run artifacts
- Add Stata dependency checker (preflight) and wire into worker execution
- Allow retry of `failed` jobs via `POST /v1/jobs/{job_id}/run` (state machine + service)
- Add tests for missing → fix → retry success

