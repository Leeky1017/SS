## 1. Implementation
- [ ] 1.1 Freeze v1 contract in `openspec/specs/ss-frontend-backend-alignment/spec.md` (redeem/auth/Step3 + error_code set)
- [ ] 1.2 Add token model + persistence and implement `POST /v1/task-codes/redeem`
- [ ] 1.3 Add Bearer auth dependency and enforce on `/v1/jobs/{job_id}/...`
- [ ] 1.4 Gate `POST /v1/jobs` with `SS_V1_ENABLE_LEGACY_POST_JOBS`

## 2. Testing
- [ ] 2.1 Add pytest coverage for redeem idempotency + non-rotating token + sliding expiration
- [ ] 2.2 Add pytest coverage for 401/403 auth error_code behavior and legacy `POST /v1/jobs` gate

## 3. Documentation
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-231.md` with commands/output and PR link
