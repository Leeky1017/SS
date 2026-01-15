# Spec: issue-483-p1-e2e-tests — System-level E2E tests

## Purpose

Add a deterministic end-to-end test suite (`tests/e2e/`) that validates SS behavior across system layers, with explicit expected outcomes for boundary cases.

## Requirements

### Requirement: E2E tests are layered and runnable

- Tests MUST live under `tests/e2e/` and be organized by system layer.
- Tests MUST use `pytest + httpx` to call the API (ASGI in-process).
- External dependencies MUST be faked/mocked:
  - LLM calls use a fake client (scriptable success/failure).
  - Stata execution uses a fake runner by default; real-Stata tests MUST auto-skip when no Stata cmd is configured.

#### Scenario: E2E suite can run locally
- **WHEN** running `pytest -q tests/e2e`
- **THEN** tests run without requiring external network services.

### Requirement: API endpoints have boundary coverage

For each of the following endpoints, tests MUST cover:
- normal inputs → expected success response
- missing required fields → `400` with stable structured error (`error_code`, `message`)
- invalid authentication (where applicable) → `401/403` with stable structured error
- resource not found → `404` with stable structured error
- operation not allowed by status → `409` with stable structured error

Endpoints:
- `POST /v1/task-codes/redeem`
- `POST /v1/jobs/{job_id}/inputs/upload`
- `GET /v1/jobs/{job_id}/draft/preview`
- `POST /v1/jobs/{job_id}/confirm`
- `POST /v1/jobs/{job_id}/run`
- `GET /v1/jobs/{job_id}/artifacts/{path}`

### Requirement: Input processing rejects unsupported formats and handles edge cases

Tests MUST cover (at minimum):
- supported formats: `.csv`, `.xls`, `.xlsx` → upload + preview succeed
- unsupported formats: `.txt`, `.zip`, images → `400 INPUT_UNSUPPORTED_FORMAT`
- empty file → `400 INPUT_EMPTY_FILE`
- encoding issues (e.g. GBK/garbled) → `400 INPUT_PARSE_FAILED` (no 500)
- excel edge cases: multi-sheet selection, missing sheet, corrupted file → explicit `400` errors

### Requirement: LLM failures are recoverable and do not corrupt state

Tests MUST cover:
- LLM timeout/failure → request returns a user-friendly error (no 500), job status does not advance, and inputs remain available
- LLM failure followed by retry → preview succeeds without re-upload

### Requirement: Confirm and correction are idempotent and enforce locking

Tests MUST cover:
- confirm transitions job to queued (normal path)
- repeated confirm is idempotent (no extra side effects)
- confirmation blocked by missing answers/unknowns → `400 DRAFT_CONFIRM_BLOCKED` with explicit missing fields
- after confirmation, mutation endpoints (inputs upload / draft patch) are rejected with `409` (locked)

### Requirement: Execution and retry behavior

Tests MUST cover:
- execution success → artifacts indexed and downloadable; job status `succeeded`
- execution failure/timeout → job status `failed` and reason recorded
- retry after failure → transitions back to queued and runs again without requiring draft regeneration

### Requirement: State machine and concurrency safety

Tests MUST cover:
- legal transitions: `created → draft_ready → confirmed → queued → running → succeeded/failed`
- illegal transitions rejected with `409 JOB_ILLEGAL_TRANSITION`
- concurrent confirm requests do not corrupt state; the loser receives a user-friendly, recoverable response

