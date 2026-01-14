# Contract alignment (delta) — Issue #464

## Goal
- Align backend Pydantic schemas/contracts and frontend TypeScript types/consumers for `/v1` endpoints without compatibility branches.

## Single source of truth
- `src/api/schemas.py` is the authoritative contract definition for v1 response payload shapes.

## Scope
- `GET /v1/jobs/{job_id}/draft/preview`
- `POST /v1/jobs/{job_id}/draft/patch`
- `POST /v1/jobs/{job_id}/confirm`
- `GET /v1/jobs/{job_id}/inputs/preview`

## Acceptance
- Audit report exists at `openspec/_ops/audits/frontend-backend-contract-alignment.md` with file+line evidence for each mismatch.
- Backend responses match `src/api/schemas.py` exactly for the endpoints above.
- Frontend types in `frontend/src/api/types.ts` (or canonical types file) match `src/api/schemas.py` exactly.
- No frontend if-else compatibility conversions based on runtime shape.

