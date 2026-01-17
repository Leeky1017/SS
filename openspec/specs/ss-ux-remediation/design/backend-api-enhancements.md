# Design: Backend API enhancements (ss-ux-remediation)

## Goals

- Extend the `/v1` API surface to support richer UX without leaking internals.
- Keep API thin: validate/DI/assemble responses; delegate business rules to domain services.
- Preserve contract discipline: backend schema/route changes first, then regenerate frontend types.

## Constraints (non-negotiable)

- All failures return structured errors with `error_code` and `message` (see `ss-api-surface`).
- Error codes are stable, UPPER_SNAKE_CASE, and inventoried in `ERROR_CODES.md`.
- Job state transitions remain state-machine driven (no ad-hoc writes).
- Frontend API types are generated; never hand-edit:
  - `frontend/src/api/types.ts`
  - `frontend/src/features/admin/adminApiTypes.ts`

Contract workflow:
- Generate: `scripts/contract_sync.sh generate`
- Check: `scripts/contract_sync.sh check`

## Proposed API additions (high level)

### 1) Upload UX improvements

- **BE-001**: chunked upload + progress-friendly model (upload sessions, chunk commit, resumable retries).
- **BE-005**: auxiliary Excel sheet selection endpoint (parity with primary sheet selection).

### 2) Download UX improvements

- **BE-002**: zip/bundle download endpoint for selected artifacts (server-side packaging).

### 3) List UX improvements

- **BE-003**: pagination API for job listing (admin and/or user-facing lists as applicable).

### 4) Polling and plan freeze reliability

- **BE-004**: draft/preview polling max retry (bounded waiting).
- **BE-008**: required variable selection support (ID/TIME etc) to prevent Plan freeze blockers.
- **BE-009**: structured Plan freeze missing-required details (actionable remediation payload).

## Backward compatibility notes

- Prefer additive changes within `/v1`.
- If any breaking change is unavoidable, it must be introduced as a new major version (`/v2`) per `ss-api-surface`.

