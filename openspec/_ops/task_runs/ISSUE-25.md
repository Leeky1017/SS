# ISSUE-25

- Issue: #25
- Branch: task/25-arch-t052-dofile-generator
- PR: (pending)

## Plan
- Spec: define DoFileGenerator contract and scenarios
- Code: deterministic do-file generation + minimal export capture
- Gates: ruff + pytest, then PR w/ auto-merge

## Runs
### 2026-01-06 21:22 setup
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 25 arch-t052-dofile-generator`
- Key output:
  - `Worktree created: .worktrees/issue-25-arch-t052-dofile-generator`
  - `Branch: task/25-arch-t052-dofile-generator`

### 2026-01-06 21:23 rulebook task
- Command:
  - `rulebook task create issue-25-arch-t052-dofile-generator`
  - `rulebook task validate issue-25-arch-t052-dofile-generator`
- Key output:
  - `✅ Task issue-25-arch-t052-dofile-generator created successfully`
  - `✅ Task issue-25-arch-t052-dofile-generator is valid`

### 2026-01-06 21:28 gates
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/python -m pytest -q`
- Key output:
  - `All checks passed!`
  - `38 passed`
