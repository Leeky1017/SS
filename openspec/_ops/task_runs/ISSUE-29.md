# ISSUE-29

- Issue: #29
- Branch: task/29-openspec-standardize
- PR: <fill-after-created>

## Plan
- Define OpenSpec writing standard + template
- Move SS canonical docs into OpenSpec
- Add CI guard for spec quality

## Runs
### 2026-01-06 setup
- Command:
  - `gh issue create ...`
  - `scripts/agent_worktree_setup.sh 29 openspec-standardize`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/29`
  - `Worktree created: .worktrees/issue-29-openspec-standardize`

### 2026-01-06 verify
- Command:
  - `python scripts/openspec_spec_guard.py`
  - `ruff check .`
  - `pytest -q`
- Key output:
  - `OpenSpec guard OK (8 specs)`
  - `All checks passed!`
  - `3 passed in 0.02s`
