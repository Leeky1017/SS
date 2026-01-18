# ISSUE-527
- Issue: #527
- Branch: task/527-be-008-id-time-var-selection
- PR: <fill-after-created>

## Plan
- Expose required ID/TIME variables in draft preview
- Accept selections in plan freeze and fill template params
- Regenerate contract types and verify checks

## Runs
### 2026-01-18 setup
- Command: `scripts/agent_worktree_setup.sh "527" "be-008-id-time-var-selection"`
- Key output: `Worktree created: .worktrees/issue-527-be-008-id-time-var-selection`

### 2026-01-18 issue
- Command: `gh issue create -t "[WAVE-1] BE-008: ID/Time variable selection" -b "<...>"`
- Key output: `https://github.com/Leeky1017/SS/issues/527`

### 2026-01-18 rulebook
- Command: `rulebook task create issue-527-be-008-id-time-var-selection`
- Key output: `Task issue-527-be-008-id-time-var-selection created successfully`

- Command: `rulebook task validate issue-527-be-008-id-time-var-selection`
- Key output: `Task issue-527-be-008-id-time-var-selection is valid`

### 2026-01-18 lint
- Command: `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output: `All checks passed!`

### 2026-01-18 typecheck
- Command: `/home/leeky/work/SS/.venv/bin/mypy`
- Key output: `Success: no issues found in 223 source files`

### 2026-01-18 tests
- Command: `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output: `437 passed, 7 skipped`

### 2026-01-18 contract
- Command: `scripts/contract_sync.sh generate`
- Key output: `ModuleNotFoundError: No module named 'fastapi'`

- Command: `PATH=/home/leeky/work/SS/.venv/bin:$PATH scripts/contract_sync.sh generate`
- Key output: `exit 0`

- Command: `PATH=/home/leeky/work/SS/.venv/bin:$PATH scripts/contract_sync.sh check`
- Key output: `exit 0`
