# Notes: issue-231-align-c002-redeem-auth

## Scope (acceptance)
- ALIGN-C001: freeze v1 contract in `openspec/specs/ss-frontend-backend-alignment/spec.md` (redeem/auth/Step3 fields + error codes).
- ALIGN-C002: implement redeem + token store/validate + pytest.
- ALIGN-C003: enforce bearer auth on job routes + gate `POST /v1/jobs` via `SS_V1_ENABLE_LEGACY_POST_JOBS`.

## Decisions
- Prefer reusing existing job persistence for token storage (avoid introducing a new database/table unless required).

## Open Questions
- None.

## Later
- Consider rate-limiting redeem and adding audit logs for token usage (out of scope for this card).

