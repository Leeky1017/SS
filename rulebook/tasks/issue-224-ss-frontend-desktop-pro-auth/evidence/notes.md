# Notes: issue-224-ss-frontend-desktop-pro-auth

## New entry + auth requirements (requested)
- Default production entry:
  - user enters `task_code` + requirement
  - `POST /v1/task-codes/redeem` -> `{job_id, token}`
  - persist token; proceed through upload/preview/blueprint/confirm/status
- Dev-only fallback:
  - allowed only when gated by build config (e.g. `VITE_REQUIRE_TASK_CODE=1`)
  - if task_code missing OR redeem endpoint not available, fallback to `POST /v1/jobs`
- Token contract:
  - storage: localStorage keys `ss.auth.v1.{job_id}` and `ss.last_job_id`
  - usage: attach `Authorization: Bearer <token>` to all `/v1/**` requests when token exists
  - invalidation: 401/403 clears token and prompts re-redeem

