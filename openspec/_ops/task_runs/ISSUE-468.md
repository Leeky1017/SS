# ISSUE-468
- Issue: #468
- Branch: task/468-align-c006-error-codes
- PR: <fill-after-created>

## Plan
- Hide internal technical terms in user-facing UI copy
- Show all user-visible errors as numeric codes + friendly text
- Add internal error code index for troubleshooting

## Runs
### 2026-01-14 15:35 issue
- Command: `gh issue create -t "[ROUND-03-ALIGN-A] ALIGN-C006: Terminology isolation + error code codification" -b "..."`
- Key output: `https://github.com/Leeky1017/SS/issues/468`
- Evidence: `.worktrees/issue-468-align-c006-error-codes/openspec/_ops/task_runs/ISSUE-468.md`

### 2026-01-14 17:07 python-env
- Command: `python3 -m venv .venv && .venv/bin/python -m pip install -e '.[dev]'`
- Key output: `Successfully installed ... ruff ... pytest ...`
- Evidence: `.venv/`

### 2026-01-14 17:07 ruff
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `pyproject.toml`

### 2026-01-14 17:07 pytest
- Command: `.venv/bin/pytest -q`
- Key output: `376 passed, 5 skipped in 15.51s`
- Evidence: `tests/`

### 2026-01-14 17:07 frontend-build
- Command: `npm --prefix frontend ci && npm --prefix frontend run build`
- Key output: `dist/ built successfully`
- Evidence: `frontend/dist/`
