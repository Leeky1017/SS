# ISSUE-93

- Issue: #93
- Branch: task/93-concurrency-tests
- PR: <fill-after-created>

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
