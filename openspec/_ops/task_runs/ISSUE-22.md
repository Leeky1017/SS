# ISSUE-22

- Issue: #22
- Branch: task/22-arch-t041-queue-claim
- PR: https://github.com/Leeky1017/SS/pull/57

## Plan
- Define queue port + file-based claim
- Implement lease expiry semantics
- Add tests for atomic claim + expiry

## Runs
### 2026-01-06 12:19 controlplane sync + worktree
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 22 arch-t041-queue-claim`
- Key output:
  - `Worktree created: .worktrees/issue-22-arch-t041-queue-claim`
- Evidence:
  - `.worktrees/issue-22-arch-t041-queue-claim`

### 2026-01-06 12:36 local checks
- Command:
  - `python3 -m venv .venv`
  - `. .venv/bin/activate && pip install -e '.[dev]'`
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `All checks passed!`
  - `23 passed in 0.28s`

### 2026-01-06 12:57 follow-up: split queue module (repo file size limit)
- Command:
  - `scripts/agent_worktree_setup.sh 22 arch-t041-queue-claim-split`
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `All checks passed!`
  - `32 passed in 0.36s`
