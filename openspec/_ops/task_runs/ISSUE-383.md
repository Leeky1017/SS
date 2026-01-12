# ISSUE-383
- Issue: #383
- Branch: task/383-fix-issue-372-evidence-pointers
- PR: https://github.com/Leeky1017/SS/pull/384

## Plan
- Update `openspec/_ops/task_runs/ISSUE-372.md` evidence pointers to the archived Rulebook task path.

## Runs
### 2026-01-12 00:00 Bootstrap
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "383" "fix-issue-372-evidence-pointers"`
  - `rulebook task create issue-383-fix-issue-372-evidence-pointers`
  - `rulebook task validate issue-383-fix-issue-372-evidence-pointers`
- Key output:
  - `Worktree created: .worktrees/issue-383-fix-issue-372-evidence-pointers`

### 2026-01-12 00:01 Fix evidence pointers
- Evidence:
  - Updated `openspec/_ops/task_runs/ISSUE-372.md` to reference `rulebook/tasks/archive/2026-01-12-issue-372-deploy-ready-r001/`.

### 2026-01-12 00:02 Local checks (ruff + pytest)
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -U pip`
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `184 passed, 5 skipped`
