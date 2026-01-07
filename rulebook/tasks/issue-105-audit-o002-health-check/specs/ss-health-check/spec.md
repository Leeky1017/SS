# Spec: ss-health-check (issue-105)

## Purpose

Provide liveness and readiness endpoints so orchestrators can safely start, stop, and rollout SS.

## Requirements

### Requirement: Liveness is process-only

SS MUST expose a liveness endpoint that stays healthy as long as the process is running, regardless of dependency availability.

#### Scenario: Liveness stays healthy when dependencies fail
- **WHEN** dependencies (storage, queue, LLM provider) are unavailable
- **THEN** `GET /health/live` returns HTTP 200 with a stable JSON schema

### Requirement: Readiness reflects dependency availability

SS MUST expose a readiness endpoint that reports dependency status and returns a failure status code when the service cannot safely serve requests.

#### Scenario: Readiness fails when a dependency is unavailable
- **WHEN** a required dependency is unavailable
- **THEN** `GET /health/ready` returns HTTP 503 and includes a structured JSON payload with per-dependency status

