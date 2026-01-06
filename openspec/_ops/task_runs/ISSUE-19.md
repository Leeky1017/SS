# ISSUE-19

- Issue: #19
- Branch: task/19-arch-t022-artifacts-api
- PR: <fill>

## Plan
- Implement artifacts index/download endpoints (path-safe).
- Implement enqueue-only run trigger (idempotent).
- Add tests + run ruff/pytest.

## Runs
### 2026-01-06 20:13 Bootstrap
- Command:
  - `scripts/agent_worktree_setup.sh 19 arch-t022-artifacts-api`
- Key output:
  - `Worktree created: .worktrees/issue-19-arch-t022-artifacts-api`
  - `Branch: task/19-arch-t022-artifacts-api`

### 2026-01-06 20:16 Lint + tests
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `25 passed`
