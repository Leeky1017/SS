# Spec Delta: issue-243-fe-a3-loop-closure

## Scope
- Implement FE-C004/005/006 in `frontend/` per `openspec/specs/ss-frontend-desktop-pro/spec.md`.

## Requirements (delta)
- Step 2 calls `POST /v1/jobs/{job_id}/inputs/upload` and `GET /v1/jobs/{job_id}/inputs/preview` and persists snapshots for refresh-resume.
- Step 3 calls `GET /v1/jobs/{job_id}/draft/preview`, best-effort `POST /v1/jobs/{job_id}/draft/patch`, and `POST /v1/jobs/{job_id}/confirm` with explicit downgrade behavior when fields/endpoints are missing.
- Status view polls `GET /v1/jobs/{job_id}` and supports listing/downloading artifacts via `GET /v1/jobs/{job_id}/artifacts` and `GET /v1/jobs/{job_id}/artifacts/{artifact_id:path}`.
