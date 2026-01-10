# ISSUE-341
- Issue: #341
- Branch: task/341-prod-e2e-r030
- PR: <fill-after-created>

## Plan
- Enforce plan-freeze missing-params gate (draft blockers + template required params)
- Return structured error payload for retry (missing + next_action)
- Add unit + integration coverage for missing params

## Runs
### 2026-01-10 deps (venv)
- Command: `python3 -m venv .venv && .venv/bin/pip install -e '.[dev]'`
- Key output: `Successfully installed ... ruff ... pytest ... ss`

### 2026-01-10 lint
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`

### 2026-01-10 tests
- Command: `.venv/bin/pytest -q`
- Key output: `182 passed, 5 skipped`

