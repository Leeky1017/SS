# Spec: ss-api-surface

## Purpose

Define the SS HTTP API surface as a thin layer that exposes job status and artifacts without leaking implementation details.

## Requirements

### Requirement: API stays thin and delegates to domain services

The API layer MUST only perform input validation, dependency injection, and response assembly, and MUST delegate business logic to domain services.

#### Scenario: API does not implement business logic
- **WHEN** reviewing `src/api/`
- **THEN** it does not implement state-machine rules or runner execution

### Requirement: Jobs status endpoint exists

SS MUST provide `GET /jobs/{job_id}` as the authoritative query endpoint returning status, timestamps, a draft summary, an artifacts summary, and the latest run attempt if present.

#### Scenario: Job query endpoint is available
- **WHEN** a client requests `GET /jobs/{job_id}`
- **THEN** the response contains status and a minimal summary without leaking internals

### Requirement: Artifacts are first-class API resources

SS MUST expose an artifacts index endpoint and a safe download endpoint that prevents path traversal and symlink escapes.

#### Scenario: Artifact download is path-safe
- **WHEN** requesting an artifact download with unsafe path components
- **THEN** SS rejects the request with a structured error

### Requirement: Run trigger is enqueue-only

SS MUST provide `POST /jobs/{job_id}/run` as an enqueue/transition trigger and MUST NOT execute Stata within the API process.

#### Scenario: Run trigger does not execute
- **WHEN** `POST /jobs/{job_id}/run` is called
- **THEN** the job transitions to `queued` and execution happens only in the worker

