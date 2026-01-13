# ISSUE-431
- Issue: #431
- Branch: task/431-windows-deploy-compat
- PR: <fill-after-created>

## Plan
- Remove Unix-only `fcntl` imports (Windows-safe file locks)
- Ensure `.env` loads on startup + serve frontend at `/`
- Add `start.ps1` and verify with `ruff` + `pytest`

## Runs
### 2026-01-13 12:04 deps
- Command: `python3 -m venv .venv && .venv/bin/python -m pip install -e ".[dev]"`
- Key output: `Successfully installed ... ruff ... httpx ...`
- Evidence: `.venv/`

### 2026-01-13 12:05 ruff
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`

### 2026-01-13 12:05 pytest
- Command: `.venv/bin/pytest -q`
- Key output: `272 passed, 5 skipped`
