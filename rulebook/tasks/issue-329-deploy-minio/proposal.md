# Proposal: issue-329-deploy-minio

## Why
Production removed the runtime fake upload object store backend (R043), but Docker deployments still need a real, local-disk-backed upload sessions backend without routing bytes through the SS API. MinIO provides an S3-compatible “real backend” that preserves the production “no fake” goal.

## What Changes
Add a new OpenSpec deployment spec and task cards describing how to run SS upload sessions with MinIO (S3-compatible) in Docker, including required config keys, endpoint reachability constraints for presigned URLs, and an operator self-check procedure.

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-minio/spec.md` (new)
- Affected code: none
- Breaking change: NO
- User benefit: A production-compatible, cloud-vendor-independent upload sessions deployment path (MinIO) with clear diagnostics and reproducible validation steps.
