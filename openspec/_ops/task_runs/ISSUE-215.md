# ISSUE-215
- Issue: #215
- Branch: task/215-stata-proxy-extension
- PR: <fill-after-created>

## Plan
- Implement backend-stata-proxy-extension proxy-layer changes (schemas + services + validation).
- Add tests for variable corrections, preview payload, and freeze failure behavior.
- Run `ruff`, `pytest`, and `openspec validate` before PR auto-merge.

## Runs
### 2026-01-09 11:35 issue
- Command: `gh issue create -t "[BACKEND] Stata Proxy Extension: variable corrections + draft preview + freeze validation" -b "<body>"`
- Key output: `https://github.com/Leeky1017/SS/issues/215`
- Evidence: `openspec/specs/backend-stata-proxy-extension/spec.md`

### 2026-01-09 12:10 validate
- Command: `rulebook task validate issue-215-stata-proxy-extension`
- Key output: `✅ Task issue-215-stata-proxy-extension is valid`
- Evidence: `rulebook/tasks/issue-215-stata-proxy-extension/`

### 2026-01-09 12:18 lint
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `.venv/`

### 2026-01-09 12:19 tests
- Command: `.venv/bin/pytest -q`
- Key output: `140 passed, 5 skipped`
- Evidence: `tests/`

### 2026-01-09 12:20 openspec
- Command: `openspec validate --specs --strict --no-interactive`
- Key output: `Totals: 22 passed, 0 failed (22 items)`
- Evidence: `openspec/specs/`
