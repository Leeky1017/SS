# Proposal: DEPLOY-MINIO-R002 (Issue #334)

## Summary

Add reusable Docker deployment assets for local single-machine usage:
- `docker-compose.yml` to start MinIO (S3-compatible) + SS
- `.env.example` with a minimal runnable configuration (upload sessions presign/finalize path)

Assets live under `openspec/specs/ss-deployment-docker-minio/assets/` as required by the spec/task card.

## Scope / non-goals

- No runtime fake backend.
- No SS code changes (unless a spec-required deploy key is missing in `src/config.py`, which is not expected).

## Verification

- `docker compose up` starts MinIO + SS.
- MinIO console is reachable on the published port and the bucket exists (auto-initialized).
- SS responds `200` on `/health/live`.
