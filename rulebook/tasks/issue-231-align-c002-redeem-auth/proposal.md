# Proposal: issue-231-align-c002-redeem-auth

## Why
- The v1 Desktop Pro flow requires a stable backend contract for redeem/auth/Step3. Without redeem + token auth, the frontend cannot complete the tokenized journey, and tests cannot lock error_code behavior.

## What Changes
- Freeze the v1 contract in `openspec/specs/ss-frontend-backend-alignment/spec.md` (redeem/auth/Step3 fields + error codes).
- Implement `POST /v1/task-codes/redeem` with idempotent `task_code → (job_id, token)` mapping and sliding expiration.
- Enforce Bearer auth on `/v1/jobs/{job_id}/...` endpoints with stable 401/403 `error_code`, and add a config gate to disable legacy `POST /v1/jobs`.

## Impact
- Affected specs: `openspec/specs/ss-frontend-backend-alignment/spec.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/`, `src/config.py`, `tests/`
- Breaking change: NO (legacy `POST /v1/jobs` stays enabled by default)
- User benefit: Enables tokenized v1 Step 3 journey and stable auth/error handling.
