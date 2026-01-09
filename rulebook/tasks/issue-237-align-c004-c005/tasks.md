## 1. Implementation
- [ ] 1.1 Align `GET /v1/jobs/{job_id}/draft/preview` to draft-v1 (200 + stable 202 pending)
- [ ] 1.2 Implement `POST /v1/jobs/{job_id}/draft/patch` patch-v1 (`field_updates` + response fields)
- [ ] 1.3 Implement `POST /v1/jobs/{job_id}/confirm` confirm-v1 persistence + blocking enforcement + plan id inputs

## 2. Testing
- [ ] 2.1 Add core tests for preview/patch/confirm branches (including confirm blocked)
- [ ] 2.2 Add user-journey test: redeem→token→upload→preview→patch→confirm
- [ ] 2.3 Add auth rejection tests: missing token (401) + wrong token (403) with stable `error_code`

## 3. Documentation
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-237.md` with commands/output and PR link

