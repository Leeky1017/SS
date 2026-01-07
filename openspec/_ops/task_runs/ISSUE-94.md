# ISSUE-94

- Issue: #94
- Branch: task/94-user-journeys
- PR: https://github.com/Leeky1017/SS/pull/98

## Plan
- Add `tests/user_journeys/` fixtures
- Implement scenarios A-D flows
- Run `.venv/bin/ruff` + `.venv/bin/pytest`

## Runs
### 2026-01-07 05:57 Setup venv + deps
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -q -e ".[dev]"`
  - `.venv/bin/pip install -q ruff`
- Key output:
  - (no output)
- Evidence:
  - `.venv/`

### 2026-01-07 05:57 Lint
- Command:
  - `.venv/bin/ruff check .`
- Key output:
  - All checks passed!

### 2026-01-07 05:57 Tests
- Command:
  - `.venv/bin/pytest -q`
- Key output:
  - 66 passed in 0.80s

### 2026-01-07 06:06 Lint + tests (with user journeys)
- Command:
  - All checks passed!
  - ......................................................................   [100%]
70 passed in 0.85s
- Key output:
  - All checks passed!
  - 70 passed in 0.80s
