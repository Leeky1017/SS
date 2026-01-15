# E2E coverage report

This file is the human-readable index of what `tests/e2e/` covers and what it intentionally skips.

## Layer 1 — API entry
- Core endpoints exercised:
  - `POST /v1/task-codes/redeem`
  - `POST /v1/jobs/{job_id}/inputs/upload`
  - `GET /v1/jobs/{job_id}/draft/preview`
  - `POST /v1/jobs/{job_id}/confirm`
  - `POST /v1/jobs/{job_id}/run`
  - `GET /v1/jobs/{job_id}/artifacts/{path}`
- Status + error coverage:
  - ✅ `200` redeem valid payload
  - ✅ `400 INPUT_VALIDATION_FAILED` redeem missing fields; inputs upload missing `file`
  - ✅ `401 AUTH_BEARER_TOKEN_MISSING` when token is absent (v1 job endpoints)
  - ✅ `401 AUTH_BEARER_TOKEN_INVALID` when `Authorization` is not a Bearer token
  - ✅ `403 AUTH_TOKEN_INVALID` when Bearer token secret is wrong
  - ✅ `404 JOB_NOT_FOUND` when job id is missing
- Files: `tests/e2e/layer1_api_entry/test_api_entry_contracts.py`

## Layer 2 — Input processing
- Supported formats → upload + preview:
  - ✅ CSV (`.csv`)
  - ✅ Excel (`.xlsx`, `.xls`)
- Content / edge cases:
  - ✅ header-only CSV has `row_count == 0`
  - ✅ multi-sheet Excel: list sheets + switch selected sheet
  - ✅ corrupted `.xlsx` returns `400 INPUT_PARSE_FAILED`
  - ✅ non-UTF8 (GBK) CSV returns `400 INPUT_PARSE_FAILED`
  - ✅ empty file returns `400 INPUT_EMPTY_FILE`
  - ✅ unsupported formats (`.txt`, `.zip`, `.png`) return `400 INPUT_UNSUPPORTED_FORMAT`
- Files: `tests/e2e/layer2_inputs/test_input_processing.py`

## Layer 3 — LLM resilience
- Provider failure behavior:
  - ✅ LLM provider error surfaces as `502 LLM_CALL_FAILED`
  - ✅ job status does not advance on LLM failure (remains `created`)
  - ✅ inputs remain accessible after LLM failure (no destructive state change)
- Recovery:
  - ✅ retrying draft preview after a transient LLM error succeeds without re-upload
- Files: `tests/e2e/layer3_llm/test_llm_resilience.py`

## Layer 4 — Confirm & correction
- Confirm validation:
  - ✅ missing answers / unresolved unknowns returns `400 DRAFT_CONFIRM_BLOCKED`
- Idempotency:
  - ✅ repeated confirm does not reschedule (`scheduled_at` stable)
- Locking after confirm:
  - ✅ inputs upload is rejected with `409 JOB_LOCKED`
  - ✅ draft patch is rejected with `409 JOB_LOCKED`
- Files: `tests/e2e/layer4_confirm/test_confirm_and_locking.py`

## Layer 5 — Execution
- Fake-runner execution (default):
  - ✅ queued job processed by worker transitions to `succeeded`
  - ✅ artifacts are indexed and downloadable
  - ✅ failure then user-triggered retry (`POST /run`) requeues and can succeed
- Real Stata smoke:
  - ✅ auto-skips when Stata is unavailable
- Files:
  - `tests/e2e/layer5_execution/test_execution_and_retry.py`
  - `tests/e2e/layer5_execution/test_real_stata_smoke.py`

## Layer 6 — State management
- State machine guardrails:
  - ✅ draft preview before inputs returns `202 pending_inputs_upload`
  - ✅ confirm/run before `draft_ready` returns `409 JOB_ILLEGAL_TRANSITION`
- Resource errors:
  - ✅ downloading unknown artifact returns `404 ARTIFACT_NOT_FOUND`
- Concurrency + idempotency:
  - ✅ concurrent confirm returns user-friendly `200` responses (no 409 surfacing)
  - ✅ redeeming the same task code twice returns the same `job_id` + `token`
- Files: `tests/e2e/layer6_state/test_state_machine_and_concurrency.py`

## Known gaps / follow-ups
- Inputs:
  - password-protected Excel, hidden sheets, formulas, “huge” datasets (performance), pathological column names
- LLM:
  - malformed/empty structured output (beyond provider timeout/exception)
- Execution:
  - explicit Stata timeout paths (current suite focuses on deterministic fake-runner outcomes)
