# ISSUE-340
- Issue: #340
- Branch: task/340-prod-e2e-r013
- PR: <fill-after-created>

## Plan
- Replace stub do-file generator with deterministic do-template rendering
- Fail fast on missing required params (structured error)
- Archive template + runner artifacts for audit

## Runs
### 2026-01-10 12:12 lint+tests
- Command: `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `pyproject.toml`

### 2026-01-10 12:12 unit
- Command: `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output: `178 passed, 5 skipped`
- Evidence: `tests/`

### 2026-01-10 12:33 mypy
- Command: `/home/leeky/work/SS/.venv/bin/mypy`
- Key output: `Success: no issues found in 154 source files`
- Evidence: `pyproject.toml`
