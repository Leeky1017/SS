# ISSUE-390
- Issue: #390
- Branch: task/390-deploy-ready-r012
- PR: https://github.com/Leeky1017/SS/pull/394

## Plan
- Specify the production Stata provisioning strategy (host-mounted) with a stable mount path and `SS_STATA_CMD` contract.
- Provide a runnable docker-compose example and clarify worker fail-fast startup behavior when Stata config/mount is missing.
- Record verification commands and key outputs as evidence for acceptance.

## Runs
### 2026-01-12 22:06 GitHub auth
- Command: `gh auth status`
- Key output: `Logged in to github.com account Leeky1017`
- Evidence: `gh auth status`

### 2026-01-12 22:07 Create issue
- Command: `gh issue create -t "[DEPLOY-READY] DEPLOY-READY-R012: Define Stata provisioning (host-mounted strategy)" ...`
- Key output: `https://github.com/Leeky1017/SS/issues/390`
- Evidence: `openspec/specs/ss-deployment-docker-readiness/task_cards/remediation__DEPLOY-READY-R012.md`

### 2026-01-12 22:08 Worktree
- Command: `scripts/agent_worktree_setup.sh "390" "deploy-ready-r012"`
- Key output: `Worktree created: .worktrees/issue-390-deploy-ready-r012`
- Evidence: `git worktree list`

### 2026-01-12 22:09 Rulebook task
- Command: `rulebook task create issue-390-deploy-ready-r012`
- Key output: `Location: rulebook/tasks/issue-390-deploy-ready-r012/`
- Evidence: `rulebook/tasks/issue-390-deploy-ready-r012/`

### 2026-01-12 22:22 Add host-mounted Stata provisioning assets
- Command: `ls -la openspec/specs/ss-deployment-docker-readiness/assets`
- Key output: `docker-compose.stata-host-mount.yml` and `.env.example`
- Evidence: `openspec/specs/ss-deployment-docker-readiness/assets/docker-compose.stata-host-mount.yml`

### 2026-01-12 22:27 Local validation environment
- Command: `python3 -m venv .venv && .venv/bin/python -m pip install -e '.[dev]'`
- Key output: `installed editable ss + dev dependencies in .venv/`
- Evidence: `.venv/` (gitignored)

### 2026-01-12 22:30 ruff
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `.venv/bin/ruff check .`

### 2026-01-12 22:30 pytest
- Command: `.venv/bin/pytest -q`
- Key output: `187 passed, 5 skipped`
- Evidence: `.venv/bin/pytest -q`

### 2026-01-12 22:31 openspec validate
- Command: `openspec validate --specs --strict --no-interactive`
- Key output: `Totals: 29 passed, 0 failed`
- Evidence: `openspec validate --specs --strict --no-interactive`

### 2026-01-12 22:34 PR preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`
- Evidence: `scripts/agent_pr_preflight.sh`

### 2026-01-12 22:35 PR created
- Command: `gh pr create ...`
- Key output: `https://github.com/Leeky1017/SS/pull/394`
- Evidence: `openspec/_ops/task_runs/ISSUE-390.md`
