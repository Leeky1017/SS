# ISSUE-471
- Issue: #471
- Branch: task/471-start-ps1-launcher
- PR: <fill>

## Plan
- Make `start.ps1` a reliable one-command Windows launcher (venv bootstrap + worker lifecycle).
- Update Windows non-Docker OpenSpec with `start.ps1` expectations.

## Runs
### 2026-01-14 22:29 issue
- Command: `gh issue create -t "[SS-WIN] start.ps1: reliable one-command launcher" -b "..."`
- Key output: `https://github.com/Leeky1017/SS/issues/471`
- Evidence: https://github.com/Leeky1017/SS/issues/471

### 2026-01-14 22:29 rulebook-task
- Command: `rulebook_task_create issue-471-start-ps1-launcher`
- Key output: `Task issue-471-start-ps1-launcher created successfully`
- Evidence: `rulebook/tasks/issue-471-start-ps1-launcher/proposal.md`

### 2026-01-14 23:08 worktree
- Command: `scripts/agent_worktree_setup.sh 471 start-ps1-launcher`
- Key output: `Worktree created: .worktrees/issue-471-start-ps1-launcher`
- Evidence: `scripts/agent_worktree_setup.sh`

### 2026-01-14 23:12 implement
- Command: `apply_patch (start.ps1 + specs + run log + rulebook task)`
- Key output: `Updated start.ps1 and Windows non-Docker OpenSpec; added Rulebook task spec + run log`
- Evidence:
  - `start.ps1`
  - `openspec/specs/ss-deployment-windows-non-docker/spec.md`
  - `rulebook/tasks/issue-471-start-ps1-launcher/`
  - `openspec/_ops/task_runs/ISSUE-471.md`

### 2026-01-14 23:15 python-env
- Command: `python3 -m venv .venv && .venv/bin/python -m pip install -e ".[dev]"`
- Key output: `Successfully installed ... ruff ... pytest ...`
- Evidence: `pyproject.toml`

### 2026-01-14 23:15 ruff
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `pyproject.toml`

### 2026-01-14 23:15 pytest
- Command: `.venv/bin/pytest -q`
- Key output: `376 passed, 5 skipped in 14.15s`
- Evidence: `tests/`

### 2026-01-14 23:16 preflight (blocked)
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `ERROR: controlplane dirty: /home/leeky/work/SS`
- Evidence: `scripts/agent_pr_preflight.sh`

### 2026-01-14 23:16 controlplane-fix
- Command: `git restore --source=HEAD --staged --worktree src/main.py && rm -f src/_deploy_test_marker.txt`
- Key output: `Controlplane clean`
- Evidence: `/home/leeky/work/SS`

### 2026-01-14 23:16 preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`
- Evidence: `scripts/agent_pr_preflight.sh`

### 2026-01-14 23:17 commit
- Command: `git commit -m "feat: harden start.ps1 launcher (#471)"`
- Key output: `feat: harden start.ps1 launcher (#471)` (includes later `--amend`)
- Evidence: `start.ps1`

### 2026-01-14 23:17 preflight (post-commit)
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`
- Evidence: `scripts/agent_pr_preflight.sh`
