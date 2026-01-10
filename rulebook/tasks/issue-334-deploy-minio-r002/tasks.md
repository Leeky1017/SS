# Tasks: DEPLOY-MINIO-R002 (Issue #334)

## Implementation

- Add `openspec/specs/ss-deployment-docker-minio/assets/docker-compose.yml` (MinIO + bucket init + SS).
- Add `openspec/specs/ss-deployment-docker-minio/assets/.env.example` (minimal runnable config).
- Update task card metadata/evidence fields to reference Issue `#334` and `openspec/_ops/task_runs/ISSUE-334.md`.

## Validation

- Start services: `docker compose --env-file .env up`
- Check MinIO console: `http://localhost:9001`
- Check SS health: `curl -fsS http://localhost:8000/health/live`

## Evidence

- Append commands + key outputs to `openspec/_ops/task_runs/ISSUE-334.md`.
