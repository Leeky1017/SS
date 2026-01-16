# Spec: ss-api-surface

## Purpose

Define the SS HTTP API surface as a thin layer that exposes job status and artifacts without leaking implementation details.

## Requirements

### Requirement: API stays thin and delegates to domain services

The API layer MUST only perform input validation, dependency injection, and response assembly, and MUST delegate business logic to domain services.

#### Scenario: API does not implement business logic
- **WHEN** reviewing `src/api/`
- **THEN** it does not implement state-machine rules or runner execution

### Requirement: API failures return structured errors (no stack traces)

All non-2xx API responses MUST return a stable structured error payload with:
- `error_code` (stable, machine-readable)
- `message` (human-readable, safe)

The API MUST NOT expose stack traces or internal exception types in responses.

Error codes MUST be stable, UPPER_SNAKE_CASE, and use a domain prefix consistent with current practice (examples: `INPUT_*`, `UPLOAD_*`, `AUTH_*`, `TASK_CODE_*`, `JOB_*`, `DRAFT_*`, `PLAN_*`, `LLM_*`, `STATA_*`).

When adding/changing error codes, the inventory in `ERROR_CODES.md` MUST be kept in sync (internal index; not user-facing).

#### Scenario: Request validation errors are stable
- **WHEN** a request is missing required fields
- **THEN** the response is HTTP `400` with `{"error_code":"INPUT_VALIDATION_FAILED","message":"..."}`

### Requirement: Stable API is served under an explicit version prefix

SS MUST serve the stable HTTP API under a major version prefix (at least `/v1`) to allow breaking changes to be introduced as `/v2`, `/v3`, etc.

Breaking changes MUST only be introduced by creating a new major version (e.g., `/v2`). Non-breaking additive changes SHOULD remain within the current major version.

#### Scenario: V1 routes are available
- **WHEN** a client requests `GET /v1/jobs/{job_id}`
- **THEN** the request is routed to the v1 API surface

### Requirement: Legacy routes are deprecated with an explicit window

When a new major version is introduced, SS MAY keep the previous version available during a defined deprecation window, but MUST emit deprecation headers so clients are not silently broken.

The deprecated surface MUST remain available for a deprecation window of at least 90 days after the deprecation announcement.

The deprecation mechanism MUST include:
- `Deprecation: true`
- `Sunset: YYYY-MM-DD` (planned removal date for the deprecated surface)

#### Scenario: Legacy routes emit deprecation headers
- **WHEN** a client requests `GET /jobs/{job_id}` during the deprecation window
- **THEN** the response includes `Deprecation` and `Sunset` headers

### Requirement: Jobs status endpoint exists

SS MUST provide `GET /v1/jobs/{job_id}` as the authoritative query endpoint returning status, timestamps, a draft summary, an artifacts summary, and the latest run attempt if present.

#### Scenario: Job query endpoint is available
- **WHEN** a client requests `GET /v1/jobs/{job_id}`
- **THEN** the response contains status and a minimal summary without leaking internals

### Requirement: Artifacts are first-class API resources

SS MUST expose an artifacts index endpoint and a safe download endpoint that prevents path traversal and symlink escapes.

#### Scenario: Artifact download is path-safe
- **WHEN** requesting an artifact download with unsafe path components
- **THEN** SS rejects the request with a structured error

### Requirement: Run trigger is enqueue-only

SS MUST provide `POST /v1/jobs/{job_id}/run` as an enqueue/transition trigger and MUST NOT execute Stata within the API process.

#### Scenario: Run trigger does not execute
- **WHEN** `POST /v1/jobs/{job_id}/run` is called
- **THEN** the job transitions to `queued` and execution happens only in the worker
