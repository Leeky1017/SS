# Spec: issue-488-p2a-backend-norms — Backend/general development norms

## Purpose

Make SS backend development norms explicit and enforceable, based on current code practices and existing error-code inventory.

## Requirements

### Requirement: Errors are structured and safe

- All HTTP API failures MUST return a stable structured error payload with `error_code` + `message` (SS `SSError` shape).
- New `error_code` values MUST follow the existing naming conventions (prefix-based, e.g. `INPUT_*`, `JOB_*`, `LLM_*`, `STATA_*`).
- User-visible failures MUST NOT expose stack traces or internal exception types.
- The error-code inventory MUST remain consistent with `ERROR_CODES.md`.

### Requirement: Logs are structured and actionable

- Logs MUST use stable event codes (existing `SS_...` convention).
- Logs MUST include required context fields (`job_id` and, when applicable, `run_id`/`step`/`tenant_id`).
- The spec MUST enumerate which operations require logs (API requests, status transitions, LLM calls, Stata execution).
- The spec MUST define log-level expectations (INFO/WARNING/ERROR) consistent with current practices.

### Requirement: State transitions are validated and concurrency-safe

- Job state transitions MUST follow the SS state machine contract.
- State changes MUST be validated at the boundary (domain) and rejected with structured errors on illegal transitions.
- Concurrent updates MUST be protected using the existing optimistic versioning strategy (job `version` / conflict errors).

