## 1. Implementation
- [x] 1.1 Add plan freeze + preview endpoints
- [x] 1.2 Confirm/run auto-freeze plan before queueing
- [x] 1.3 Persist plan to job.json + artifacts + index

## 2. Testing
- [x] 2.1 Update user journeys to use HTTP plan path
- [x] 2.2 Add HTTP tests for idempotency + conflict
- [x] 2.3 Run `.venv/bin/ruff check .`
- [x] 2.4 Run `.venv/bin/pytest -q`

## 3. Delivery
- [x] 3.1 Update `openspec/_ops/task_runs/ISSUE-127.md`
- [x] 3.2 Run `scripts/agent_pr_preflight.sh`
- [x] 3.3 Open PR with `Closes #127` + enable auto-merge
