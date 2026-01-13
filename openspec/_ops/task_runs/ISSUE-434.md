# ISSUE-434
- Issue: #434
- Branch: `task/434-inputs-multifile-sheet-preview`
- PR: https://github.com/Leeky1017/SS/pull/435

## Goal
- Support 1 primary + 0..N auxiliary uploads, Excel sheet selection for preview/execution, and a more usable inputs preview UI.

## Status
- CURRENT: PR open with auto-merge enabled; fixing CI gate failures (OpenSpec strict + mypy) and pushing follow-up commit.

## Next Actions
- [x] Commit changes and push branch
- [x] Create PR and enable auto-merge
- [ ] Push CI fixes, watch checks, verify merge

## Decisions Made
- 2026-01-13: Use `primary_dataset` + `auxiliary_data` roles; persist Excel `sheet_name` into `inputs/manifest.json`.
- 2026-01-13: Preview defaults to 20×10 with sticky row index; normalize blank/`Unnamed:*` headers to `col_<n>`; persist inferred `header_row` for repeatable Excel previews.

## Errors Encountered
- 2026-01-13: System `pytest` failed due to missing deps (e.g. `pydantic`) → run tests in `.venv` and install dev deps (`pytest`, `jsonschema`, `pyfakefs`).
- 2026-01-13: `gh` intermittently fails with `net/http: TLS handshake timeout` → retry `gh` commands up to 3 times with a 10s backoff.
- 2026-01-13: CI failed due to OpenSpec strict requirement formatting + new mypy errors → update spec scenarios and fix typing.

## Runs
### 2026-01-13 setup
- Command: `gh issue create ...`
- Key output: `https://github.com/Leeky1017/SS/issues/434`
- Evidence: `rulebook/tasks/issue-434-inputs-multifile-sheet-preview/`

### 2026-01-13 15:53 lint
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `src/domain/dataset_preview.py`, `src/domain/job_inputs_service.py`, `src/api/inputs_primary_sheet.py`

### 2026-01-13 15:53 tests
- Command:
  - `.venv/bin/pip install -q pytest jsonschema pyfakefs`
  - `.venv/bin/python -m pytest -q`
- Key output: `276 passed, 5 skipped`
- Evidence: `tests/test_inputs_sheet_selection_api.py`, `tests/test_job_inputs_auxiliary_role_api.py`, `tests/test_inputs_preview_header_normalization.py`

### 2026-01-13 16:41 PR
- Command:
  - `git push -u origin HEAD`
  - `scripts/agent_pr_preflight.sh`
  - `gh pr create ...`
  - `gh pr merge --auto --squash 435`
- Key output:
  - `https://github.com/Leeky1017/SS/pull/435`
  - `auto-merge enabled`
- Evidence: `openspec/_ops/task_runs/ISSUE-434.md`

### 2026-01-13 16:41 CI gate check (local)
- Command:
  - `openspec validate --specs --strict --no-interactive`
  - `.venv/bin/mypy`
  - `.venv/bin/python -m pytest -q --cov=src --cov-fail-under=80`
- Key output:
  - `OpenSpec validate: passed`
  - `mypy: passed`
  - `coverage: 80.06% (>= 80%)`
- Evidence: `.github/workflows/ci.yml`, `.github/workflows/merge-serial.yml`
