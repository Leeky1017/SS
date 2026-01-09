# Proposal: issue-237-align-c004-c005

## Why
- Step 3 currently has frontend “downgrade” paths when backend is missing fields/patch behavior/blocking enforcement, which allows confirm to be bypassed and makes user-journey tests unstable.

## What Changes
- Align `GET /v1/jobs/{job_id}/draft/preview` with draft-v1 (including stable 202 pending shape).
- Implement `POST /v1/jobs/{job_id}/draft/patch` patch-v1 (`field_updates` + `patched_fields` + `remaining_unknowns_count` + `draft_preview`).
- Implement `POST /v1/jobs/{job_id}/confirm` confirm-v1 persistence + backend-side blocking rules (`DRAFT_CONFIRM_BLOCKED`) and ensure confirm payload contributes to plan id inputs.
- Add FastAPI TestClient user-journey tests (redeem→token→upload→preview→patch→confirm) plus auth rejection coverage.

## Impact
- Affected specs: `openspec/specs/ss-frontend-backend-alignment/spec.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/`, `tests/`
- Breaking change: NO (tightens Step3 semantics for redeem-created jobs, while keeping legacy flows working)
- User benefit: Stable Step3 UX, no bypass for blocking items, and regression-proof end-to-end backend contract.

