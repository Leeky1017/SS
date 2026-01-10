## 1. Implementation
- [ ] 1.1 Remove legacy `POST /v1/jobs` endpoint in `src/api/jobs.py`
- [ ] 1.2 Remove config toggle `v1_enable_legacy_post_jobs` and all references
- [ ] 1.3 Update any tests/scripts/docs to use `POST /v1/task-codes/redeem`

## 2. Validation
- [ ] 2.1 `ruff check .`
- [ ] 2.2 `pytest -q`

## 3. Delivery
- [ ] 3.1 Update run log: `openspec/_ops/task_runs/ISSUE-314.md`
- [ ] 3.2 Run `scripts/agent_pr_preflight.sh`
- [ ] 3.3 Open PR and enable auto-merge; verify PR is `MERGED`
- [ ] 3.4 Sync controlplane `main` and cleanup worktree

