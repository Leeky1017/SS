# Spec delta: ss-deployment-docker-minio (issue-339-deploy-minio-r003)

Canonical spec: `openspec/specs/ss-deployment-docker-minio/spec.md`.

## Delta

- Add a repeatable E2E self-check asset under `openspec/specs/ss-deployment-docker-minio/assets/` that validates Docker + MinIO upload sessions:
  - `direct` presign + PUT + finalize
  - `multipart` presign + refresh-urls + part PUTs (capture `ETag`) + finalize
  - verify `inputs/preview` and `job.json.inputs.*` invariants

