# Proposal: issue-105-audit-o002-health-check

## Summary

ADDED:
- `GET /health/live` for liveness probing (process-level health)
- `GET /health/ready` for readiness probing (dependency-aware health)

MODIFIED:
- API router wiring to mount health endpoints

## Impact

- Enables Kubernetes/Docker Compose to make safe rollout decisions (restart vs. remove-from-service).
- Readiness reports structured dependency status and returns `503` when unhealthy.

