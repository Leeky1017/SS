# ISSUE-17

- Issue: #17
- Branch: task/17-arch-t012
- PR: (pending)

## Plan
- Define domain state machine (statuses, allowed transitions, guard)
- Define idempotency key + deterministic job identity
- Add unit tests for transitions + idempotency

## Runs
### 2026-01-06 10:23 controlplane sync + worktree
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 17 arch-t012`
- Key output:
  - `Worktree created: .worktrees/issue-17-arch-t012`
- Evidence:
  - `.worktrees/issue-17-arch-t012`

### 2026-01-06 10:36 local checks
- Command:
  - `python3 -m venv .venv`
  - `. .venv/bin/activate && pip install -e '.[dev]'`
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `All checks passed!`
  - `12 passed in 0.05s`
- Evidence:
  - `tests/`
