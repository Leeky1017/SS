## 1. Implementation
- [ ] 1.1 Scaffold `frontend/` (Vite + React + TypeScript)
- [ ] 1.2 Migrate Desktop Pro CSS baseline (tokens + primitives + theme toggle)
- [ ] 1.3 Add typed `/v1` API client (base url + request id + auth + 401/403 handling)
- [ ] 1.4 Implement Step 1 UI: redeem / dev fallback to `POST /v1/jobs` (gated)
- [ ] 1.5 Persist `ss.last_job_id` + `ss.auth.v1.{job_id}` + restore on refresh

## 2. Testing
- [ ] 2.1 `cd frontend && npm ci && npm run build`

## 3. Documentation / Evidence
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-232.md` with key runs + outputs
- [ ] 3.2 Ensure PR body includes `Closes #232`
