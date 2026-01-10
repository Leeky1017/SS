# ISSUE-317
- Issue: #317 https://github.com/Leeky1017/SS/issues/317
- Branch: task/317-prod-e2e-r042
- PR: <fill-after-created>

## Plan
- Remove worker fake-runner fallback; fail fast on missing `SS_STATA_CMD`.
- Migrate tests to injected `tests/**` fake runner.
- Run `ruff` + `pytest` and open PR with auto-merge.

## Runs
### 2026-01-10 Setup: venv + deps
- Command: `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
- Key output: `Successfully installed ... ss-0.0.0 ... ruff ... pytest ... pydantic ...`

### 2026-01-10 Validation: ruff + pytest
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Command: `.venv/bin/pytest -q`
- Key output: `170 passed, 5 skipped`
