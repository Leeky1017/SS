# Proposal: issue-443-archive-docker

## Why
SS is deployed directly (non-Docker). Keeping a repo-root Dockerfile/docker-compose suggests a supported Docker deployment path and confuses operators.

## What Changes
- Archive repo-root Docker deployment artifacts under `legacy/docker/`.
- Archive Docker-only deployment OpenSpecs under `openspec/specs/archive/`.
- Document the non-Docker deployment stance in the canonical Windows non-Docker deployment spec.

## Impact
- Affected specs:
  - `openspec/specs/ss-deployment-windows-non-docker/spec.md`
  - `openspec/specs/ss-deployment-docker-readiness/` (archived)
  - `openspec/specs/ss-deployment-docker-minio/` (archived)
- Affected code:
  - `Dockerfile`
  - `docker-compose.yml`
  - `.dockerignore`
- Breaking change: YES (Docker deployment artifacts are no longer repo-root)
- User benefit: removes misleading deployment path; keeps historical Docker assets discoverable.
