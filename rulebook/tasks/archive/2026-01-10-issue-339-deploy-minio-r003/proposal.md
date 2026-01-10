# Proposal: issue-339-deploy-minio-r003

## Why
Docker + MinIO deployments fail most often on presigned URL reachability and multipart `ETag` handling; a runnable self-check removes ambiguity and speeds up incident triage.

## What Changes
- Add a repeatable local/remote E2E self-check script under `openspec/specs/ss-deployment-docker-minio/assets/`.
- Cover both `direct` and `multipart` upload-session flows including `refresh-urls`, `finalize`, and `inputs/preview`/`job.json` verification.

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-minio/spec.md` (verification pointer)
- Affected code: none (assets only)
- Breaking change: NO
- User benefit: One-command self-check for Docker + MinIO uploads, including multipart `ETag` capture instructions.
