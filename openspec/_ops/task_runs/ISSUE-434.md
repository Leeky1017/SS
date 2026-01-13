# ISSUE-434
- Issue: #434
- Branch: `task/434-inputs-multifile-sheet-preview`
- PR: <fill-after-created>

## Goal
- Support 1 primary + 0..N auxiliary uploads, Excel sheet selection for preview/execution, and a more usable inputs preview UI.

## Status
- CURRENT: Implementation complete; `ruff check .` and `pytest -q` pass; ready to commit + open PR.

## Next Actions
- [ ] Commit changes and push branch
- [ ] Create PR, enable auto-merge, backfill PR link here
- [ ] Verify merge, sync controlplane `main`, cleanup worktree

## Decisions Made
- 2026-01-13: Use `primary_dataset` + `auxiliary_data` roles; persist Excel `sheet_name` into `inputs/manifest.json`.
- 2026-01-13: Preview defaults to 20×10 with sticky row index; normalize blank/`Unnamed:*` headers to `col_<n>`; persist inferred `header_row` for repeatable Excel previews.

## Errors Encountered
- 2026-01-13: System `pytest` failed due to missing deps (e.g. `pydantic`) → run tests in `.venv` and install dev deps (`pytest`, `jsonschema`, `pyfakefs`).

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
