# ISSUE-523
- Issue: #523
- Branch: task/523-be-007-column-name-normalization
- PR: https://github.com/Leeky1017/SS/pull/525

## Plan
- Add stable Stata-safe column normalization
- Surface mapping in draft preview for confirmation
- Regenerate contract types and verify checks

## Runs
### 2026-01-18 setup
- Command: `scripts/agent_worktree_setup.sh "523" "be-007-column-name-normalization"`
- Key output: `Worktree created: .worktrees/issue-523-be-007-column-name-normalization`

### 2026-01-18 issue
- Command: `gh issue create -t "[WAVE-1] BE-007: Column name normalization" -b "<...>"`
- Key output: `https://github.com/Leeky1017/SS/issues/523`

### 2026-01-18 rulebook
- Command: `rulebook task create issue-523-be-007-column-name-normalization`
- Key output: `Task issue-523-be-007-column-name-normalization created successfully`

- Command: `rulebook task validate issue-523-be-007-column-name-normalization`
- Key output: `Task issue-523-be-007-column-name-normalization is valid`

### 2026-01-18 contract
- Command: `PATH=/home/leeky/work/SS/.venv/bin:$PATH scripts/contract_sync.sh generate`
- Key output: `frontend/src/api/types.ts updated`

- Command: `PATH=/home/leeky/work/SS/.venv/bin:$PATH scripts/contract_sync.sh check`
- Key output: `exit 0`

### 2026-01-18 tests
- Command: `PATH=/home/leeky/work/SS/.venv/bin:$PATH ruff check .`
- Key output: `All checks passed!`

- Command: `PATH=/home/leeky/work/SS/.venv/bin:$PATH mypy`
- Key output: `Success: no issues found in 222 source files`

- Command: `PATH=/home/leeky/work/SS/.venv/bin:$PATH pytest -q`
- Key output: `435 passed, 7 skipped`
