## 1. Implementation
- [ ] 1.1 Add repo-root `docker-compose.yml` with `minio` + `ss-api` + `ss-worker`
- [ ] 1.2 Share `ss-jobs`/`ss-queue` volumes across API/worker at `/var/lib/ss/*`
- [ ] 1.3 Wire host-mounted Stata + do-template library env injection in compose
- [ ] 1.4 Add MinIO bucket init one-shot for `SS_UPLOAD_S3_BUCKET`

## 2. Testing
- [ ] 2.1 Validate compose renders: `docker compose config`
- [ ] 2.2 If Docker available: `docker compose up` starts worker with complete config

## 3. Documentation
- [ ] 3.1 Record evidence in `openspec/_ops/task_runs/ISSUE-403.md`
