# Spec: ss-admin-console

## Purpose

Define the SS admin console surface (UI + HTTP) for operational management: admin authentication, Task Code lifecycle, job monitoring, and system status.

## Requirements

### Requirement: Admin UI is served at `/admin`

SS MUST serve an admin frontend entry at `GET /admin` (or a safe redirect to `/admin/`) from the same server process that serves the public UI.

#### Scenario: Admin UI is reachable
- **WHEN** a browser requests `GET /admin`
- **THEN** it receives the admin frontend HTML entrypoint

### Requirement: Admin APIs are isolated under `/api/admin/*`

Admin-only operations MUST be served under `/api/admin/*` and MUST use an admin authentication model that is independent from `/v1` job bearer tokens.

#### Scenario: Admin endpoints require admin auth
- **WHEN** a client calls `GET /api/admin/jobs` without an admin token
- **THEN** SS rejects the request with a stable structured auth error

### Requirement: Admin tokens are revocable and not stored in plaintext

SS MUST support multiple admin tokens (e.g., interactive session tokens and long-lived personal tokens).
Admin tokens MUST be revocable and MUST NOT be stored in plaintext at rest (hashing required).

#### Scenario: Revoked admin token is rejected
- **WHEN** a token is revoked via `/api/admin/tokens/{token_id}/revoke`
- **THEN** subsequent requests using that token are rejected with an auth error

### Requirement: Task Codes have an explicit lifecycle

SS MUST treat Task Codes as issued resources with an explicit lifecycle:
- `unused` (issued, not yet redeemed)
- `used` (redeemed and bound to a job id)
- `expired` (past `expires_at`)
- `revoked` (manually revoked)

Task Code redemption MUST reject `expired` and `revoked` codes with a stable structured error.

#### Scenario: Redeeming an unused Task Code marks it used
- **WHEN** a client redeems a valid unused Task Code via `/v1/task-codes/redeem`
- **THEN** a job is created and the Task Code is marked `used` with the resulting `job_id`

### Requirement: Admin can monitor and operate jobs

SS MUST provide admin endpoints to:
- list jobs (including `status`, `created_at`, and a best-effort `updated_at`)
- view job details (requirement, draft, artifacts index)
- retry failed jobs
- download job artifacts with the same path-safety guarantees as the public API

#### Scenario: Admin retries a failed job
- **WHEN** an admin calls `POST /api/admin/jobs/{job_id}/retry` for a `failed` job
- **THEN** the job transitions to `queued` and is scheduled for worker execution

### Requirement: Admin can view system status

SS MUST expose an admin system status endpoint that reports:
- API health readiness summary
- queue depth (queued/claimed)
- worker status best-effort signal

#### Scenario: Admin system status is available
- **WHEN** an admin calls `GET /api/admin/system/status`
- **THEN** the response includes health + queue metrics

