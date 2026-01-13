# Spec: issue-433-admin-console

## Purpose

Define the minimal admin console capabilities for SS operations: admin authentication, Task Code lifecycle management, job monitoring, and system status visibility.

## Requirements

### Requirement: Admin APIs are isolated under `/api/admin/*`

Admin-only functionality MUST be served under `/api/admin/*` and MUST NOT share the job bearer token model used by `/v1` endpoints.

#### Scenario: Admin endpoints are distinct from v1 endpoints
- **WHEN** a client calls `/api/admin/jobs`
- **THEN** the request is authenticated via admin auth and is not subject to `/v1` bearer token enforcement

### Requirement: Admin UI is reachable at `/admin`

The admin console MUST be served by the same SS server and be reachable at `GET /admin` (or a safe redirect to `/admin/`).

#### Scenario: Admin UI is reachable
- **WHEN** a browser visits `/admin`
- **THEN** it receives the admin frontend entrypoint

