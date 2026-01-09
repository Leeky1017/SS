# ISSUE-237
- Issue: #237
- Branch: task/237-align-c004-c005
- PR: <fill-after-created>

## Goal
- ALIGN-C004: Align Step3 draft preview/patch/confirm backend contract (v1), enforce confirm blocking rules, and persist confirm payload into plan id inputs.
- ALIGN-C005: Add FastAPI TestClient user-journey tests locking the redeem→token→upload→preview→patch→confirm flow and auth error_code stability.

## Status
- CURRENT: Implement Step3 v1 contract alignment + user-journey tests.

## Next Actions
- [ ] Align draft preview/patch/confirm contract and enforce confirm blocking.
- [ ] Add user-journey integration tests for tokenized Step3 flow.
- [ ] Run `ruff check .` and `pytest -q`; record outputs; open PR with auto-merge.

## Decisions Made
- 2026-01-09 Combine ALIGN-C004 and ALIGN-C005 in one PR → reduces drift between contract and journey tests.

## Errors Encountered

## Runs

### 2026-01-09 env + deps
- Command:
  - `python3 -m venv .venv && .venv/bin/python -m pip install -U pip && .venv/bin/python -m pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... ruff-0.14.11 ... pytest-9.0.2 ...`
- Evidence:
  - `.venv/`

### 2026-01-09 ruff
- Command:
  - `.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`

### 2026-01-09 pytest
- Command:
  - `.venv/bin/pytest -q`
- Key output:
  - `154 passed, 5 skipped`
