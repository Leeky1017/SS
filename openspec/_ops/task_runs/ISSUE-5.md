# ISSUE-5

- Issue: #5
- Branch: task/5-agent-automerge-sync
- PR: https://github.com/Leeky1017/SS/pull/6

## Plan
- Add script to auto-create PR + enable auto-merge + wait + sync local main
- Make controlplane sync script work from worktrees

## Runs
### 2026-01-06 verify
- Command:
  - `ruff check .`
  - `pytest -q`
- Key output:
  - `All checks passed!`
  - `3 passed in 0.01s`
