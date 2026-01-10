# ISSUE-295
- Issue: #295
- Branch: task/295-phase-5-9-ti-tj
- PR: https://github.com/Leeky1017/SS/pull/302

## Plan
- Add best-practice review blocks to TI/TJ templates
- Strengthen validation + diagnostics (PH test, competing risks)
- Record smoke-suite (or unavailability) evidence

## Runs
### 2026-01-10 bootstrap
- Command: `rulebook task create issue-295-phase-5-9-ti-tj && rulebook task validate issue-295-phase-5-9-ti-tj`
- Key output: `Task issue-295-phase-5-9-ti-tj is valid (warnings: no spec files found)`
- Evidence: `.worktrees/issue-295-phase-5-9-ti-tj/rulebook/tasks/issue-295-phase-5-9-ti-tj/`

### 2026-01-10 quality-gates
- Command: `/tmp/ss-venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `pyproject.toml` (ruff config)

### 2026-01-10 tests
- Command: `/tmp/ss-venv/bin/pytest -q`
- Key output: `162 passed, 5 skipped`
- Evidence: `tests/`

### 2026-01-10 smoke-suite
- Command: `/tmp/ss-venv/bin/python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-271.ti01-ti11.tj01-tj06.1.0.json --report-path rulebook/tasks/issue-295-phase-5-9-ti-tj/evidence/smoke_suite_report.issue-295.json --timeout-seconds 30`
- Key output: `summary: passed=16 missing_deps=1 (stcure)`
- Evidence: `rulebook/tasks/issue-295-phase-5-9-ti-tj/evidence/smoke_suite_report.issue-295.json`
