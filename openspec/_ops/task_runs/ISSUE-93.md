# ISSUE-93

- Issue: #93
- Branch: task/93-concurrency-tests
- PR: https://github.com/Leeky1017/SS/pull/97

## Plan
- Add `tests/concurrent/` fixtures
- Implement concurrency scenarios 1–4 tests
- Run repeated tests to catch races

## Runs
### 2026-01-07 controlplane sync + worktree setup
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "93" "concurrency-tests"`
- Key output:
  - `Worktree created: .worktrees/issue-93-concurrency-tests`
  - `Branch: task/93-concurrency-tests`

### 2026-01-07 ruff + concurrent pytest (repeat)
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest tests/concurrent/ -v --count=10`
- Key output:
  - `All checks passed!`
  - `40 passed`

### 2026-01-07 PR preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-07 enable PR auto-merge
- Command:
  - `gh pr merge 97 --auto --squash`
- Key output:
  - `will be automatically merged`
