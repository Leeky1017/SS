# ISSUE-296
- Issue: #296
- Branch: task/296-phase-5-10-tk
- PR: <fill-after-created>

## Plan
- Add best-practice review blocks to TK templates
- Strengthen data-shape/missing/outlier guardrails + inference choices
- Record smoke-suite (or unavailability) evidence

## Runs
### 2026-01-10 bootstrap
- Command: `rulebook task create issue-296-phase-5-10-tk && rulebook task validate issue-296-phase-5-10-tk`
- Key output: `Task issue-296-phase-5-10-tk is valid (warnings: no spec files found)`
- Evidence: `.worktrees/issue-296-phase-5-10-tk/rulebook/tasks/issue-296-phase-5-10-tk/`

### 2026-01-10 quality-gates
- Command: `/tmp/ss-venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `pyproject.toml` (ruff config)

### 2026-01-10 tests
- Command: `/tmp/ss-venv/bin/pytest -q`
- Key output: `162 passed, 5 skipped`
- Evidence: `tests/`

### 2026-01-10 smoke-suite
- Command: `/tmp/ss-venv/bin/python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-280.tk01-tk20.1.0.json --report-path rulebook/tasks/issue-296-phase-5-10-tk/evidence/smoke_suite_report.issue-296.json --timeout-seconds 30`
- Key output: `summary: passed=20`
- Evidence: `rulebook/tasks/issue-296-phase-5-10-tk/evidence/smoke_suite_report.issue-296.json`
