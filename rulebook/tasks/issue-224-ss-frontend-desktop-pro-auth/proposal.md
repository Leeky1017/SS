# Proposal: issue-224-ss-frontend-desktop-pro-auth

## Why
The `ss-frontend-desktop-pro` spec currently assumes `POST /v1/jobs` as the only entry path. We need to make task-code redeem + token auth the default production flow, and define a dev-only fallback for local development and backward compatibility.

## What Changes
- Update `openspec/specs/ss-frontend-desktop-pro/spec.md`:
  - Define production entry via `POST /v1/task-codes/redeem` returning `{job_id, token}`.
  - Define `VITE_REQUIRE_TASK_CODE` to gate the dev-only fallback to `POST /v1/jobs`.
  - Define token persistence keys and Authorization header behavior for all `/v1/**` requests, including 401/403 invalidation UX.
- Update FE-C002 and FE-C003 task cards to reflect the new responsibilities and acceptance criteria.
- Add run log `openspec/_ops/task_runs/ISSUE-224.md`.

## Impact
- Affected specs:
  - `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Affected code:
  - None (spec/task-cards-only)
- Breaking change: NO (spec update; implementation will follow in FE-C00x issues)
- User benefit: a production-ready auth + entry contract for the frontend with a dev-only escape hatch.
