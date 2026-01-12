# Proposal: issue-403-deploy-ready-r011

## Why
SS production Docker topology currently lacks a worker service, so queued jobs cannot complete end-to-end (API can enqueue but nothing executes). A repo-root `docker-compose.yml` with `minio` + `ss-api` + `ss-worker` is needed for deploy-ready topology and E2E verification.

## What Changes
- Add a repo-root `docker-compose.yml` defining `minio`, `ss-api`, and `ss-worker`.
- Ensure `ss-api` and `ss-worker` share durable `ss-jobs` / `ss-queue` volumes at `/var/lib/ss/jobs` and `/var/lib/ss/queue`.
- Wire the host-mounted Stata strategy (bind mount + `SS_STATA_CMD`) and explicitly inject `SS_DO_TEMPLATE_LIBRARY_DIR`.
- Provide a MinIO bucket init one-shot to make the compose topology self-contained for uploads.

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-readiness/spec.md`, `openspec/specs/ss-deployment-docker-minio/spec.md`
- Affected code: repo-root `docker-compose.yml`
- Breaking change: NO
- User benefit: operators can `docker compose up` a full topology (API + worker + S3-compatible store) with durable state and explicit Stata/do-lib wiring.
