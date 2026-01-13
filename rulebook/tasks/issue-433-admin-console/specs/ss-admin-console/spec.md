# Delta Spec: ss-admin-console (Issue #433)

Canonical spec: `openspec/specs/ss-admin-console/spec.md`.

## Key Scenarios

### Scenario: Admin UI is reachable at `/admin`
- **WHEN** a browser requests `GET /admin`
- **THEN** it is redirected to `/admin/` and receives the frontend HTML entrypoint

### Scenario: Admin endpoints require admin auth
- **WHEN** a client calls `GET /api/admin/tokens` without an admin token
- **THEN** it receives `401` with error code `ADMIN_BEARER_TOKEN_MISSING`

### Scenario: Admin can create and list Task Codes
- **WHEN** an admin calls `POST /api/admin/task-codes` with `count > 1`
- **THEN** it receives a list of issued codes (initial status `unused`)

