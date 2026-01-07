## 1. Implementation
- [ ] 1.1 Add plan freeze + preview endpoints
- [ ] 1.2 Confirm/run auto-freeze plan before queueing
- [ ] 1.3 Persist plan to job.json + artifacts + index

## 2. Testing
- [ ] 2.1 Update user journeys to use HTTP plan path
- [ ] 2.2 Add HTTP tests for idempotency + conflict
- [ ] 2.3 Run `.venv/bin/ruff check .`
- [ ] 2.4 Run `.venv/bin/pytest -q`

## 3. Delivery
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-127.md`
- [ ] 3.2 Run `scripts/agent_pr_preflight.sh`
- [ ] 3.3 Open PR with `Closes #127` + enable auto-merge

