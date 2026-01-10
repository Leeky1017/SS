## 1. Implementation
- [ ] Add a repeatable self-check script under `openspec/specs/ss-deployment-docker-minio/assets/`.
- [ ] Ensure the flow covers: bundle → upload session (direct + multipart) → PUT upload → refresh-urls → finalize → inputs/preview + job.json validation.
- [ ] Document multipart `ETag` capture from each `PUT` response header and passing `{part_number, etag}` into finalize.

## 2. Testing
- [ ] Run the self-check against Docker+MinIO locally and record evidence in `openspec/_ops/task_runs/ISSUE-339.md`.

## 3. Documentation
- [ ] Add a short pointer in `openspec/specs/ss-deployment-docker-minio/spec.md` to the self-check asset(s).
