## 1. Implementation
- [ ] 1.1 Add domain service for listing artifacts for a job
- [ ] 1.2 Add domain service for safe artifact file resolution
- [ ] 1.3 Add domain service for enqueue-only run trigger (idempotent)
- [ ] 1.4 Wire API routes for artifacts index/download and run trigger

## 2. Testing
- [ ] 2.1 Test rejects unsafe paths / symlink escapes
- [ ] 2.2 Test missing artifact returns 404-style error
- [ ] 2.3 Test repeated run trigger is idempotent

## 3. Delivery
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-19.md` with commands/outputs
- [ ] 3.2 Run `ruff check .` and `pytest -q`
- [ ] 3.3 Open PR with `Closes #19` and enable auto-merge

