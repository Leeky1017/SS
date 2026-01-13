# ISSUE-445

- Issue: #445
- Branch: task/445-frontend-static-mount
- PR: https://github.com/Leeky1017/SS/pull/446

## Goal
- Ensure the frontend static mount does not shadow API routing semantics (unknown POST paths return 404, not 405).
- Make production-startup upload-store tests deterministic even when a local `.env` exists.

## Status
- CURRENT: Implementing static mount wrapper + regression tests in worktree.

## Next Actions
- [x] Add a StaticFiles wrapper that returns 404 for non-GET/HEAD
- [x] Add regression tests for POST unknown paths with `frontend/dist` present
- [x] Make production-startup upload-store test robust vs local `.env`
- [x] Run `openspec validate`, `ruff`, `mypy`, `pytest`
- [ ] Open PR + enable auto-merge; confirm merged; sync controlplane; cleanup worktree

## Runs
### 2026-01-13 19:50 Task start
- Command:
  - `gh issue create ...`
  - `scripts/agent_worktree_setup.sh 445 frontend-static-mount`
- Key output:
  - `Issue: https://github.com/Leeky1017/SS/issues/445`
  - `Worktree: .worktrees/issue-445-frontend-static-mount`

### 2026-01-13 20:05 Implement static mount wrapper + regression tests
- Evidence:
  - `src/main.py`
  - `tests/test_frontend_static_mount.py`
  - `tests/test_production_startup_upload_store.py`

### 2026-01-13 20:10 Validate
- Command:
  - `openspec validate --specs --strict --no-interactive`
  - `ruff check .`
  - `mypy`
  - `pytest -q`
- Key output:
  - `Totals: 29 passed, 0 failed (29 items)`
  - `All checks passed!`
  - `Success: no issues found in 199 source files`
  - `298 passed, 5 skipped`
