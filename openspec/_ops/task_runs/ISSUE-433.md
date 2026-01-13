# ISSUE-433

- Issue: #433
- Branch: task/433-admin-console
- PR: https://github.com/Leeky1017/SS/pull/436

## Plan
- Add `/api/admin/*` surface with admin auth + stores
- Add `/admin` frontend entry matching existing style
- Add tests and ship via PR + auto-merge

## Goal
- Deliver SS admin console surface (UI + HTTP) at `/admin` and `/api/admin/*`.

## Status
- CURRENT: PR #436 auto-merge enabled but blocked by `ci` coverage gate; added admin API tests to raise coverage to >=80 and preparing push.

## Next Actions
- [ ] Commit + push coverage-fix tests
- [ ] Watch PR checks; confirm auto-merge completes
- [ ] Verify merged; sync controlplane main; cleanup worktree

## Decisions Made
- 2026-01-13 Serve `/admin/` with `frontend/dist/index.html` and switch UI by pathname.
- 2026-01-13 Use file-backed admin stores under `SS_ADMIN_DATA_DIR` (default: `jobs/_admin`).

## Errors Encountered
- 2026-01-13 `pytest -q` failures after adding admin config fields → updated tests that construct `Config(...)`.
- 2026-01-13 PR `ci` coverage gate failed (`79.49% < 80%`) → added admin API tests; local coverage now `80.44%`.

## Runs
### 2026-01-13 00:00 Task start
- Command:
  - `gh issue create -t "Admin: SS 管理后台开发" -b "<...>"`
  - `scripts/agent_worktree_setup.sh 433 admin-console`
- Key output:
  - `Issue: https://github.com/Leeky1017/SS/issues/433`
  - `Worktree created: .worktrees/issue-433-admin-console`
- Evidence:
  - `openspec/specs/ss-admin-console/spec.md`
  - `rulebook/tasks/issue-433-admin-console/`

### 2026-01-13 00:10 Validate specs
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 31 passed, 0 failed (31 items)`

### 2026-01-13 00:11 Lint
- Command:
  - `ruff check .`
- Key output:
  - `All checks passed!`

### 2026-01-13 00:12 Typecheck
- Command:
  - `mypy`
- Key output:
  - `Success: no issues found in 197 source files`

### 2026-01-13 00:13 Tests
- Command:
  - `pytest -q`
- Key output:
  - `284 passed, 5 skipped`

### 2026-01-13 10:05 Diagnose CI coverage gate
- Command:
  - `gh run view 20951885112 --log-failed`
- Key output:
  - `ERROR: Coverage failure: total of 79 is less than fail-under=80`
  - `src/api/admin/jobs.py 43%`
  - `src/api/admin/system.py 50%`
  - `src/api/admin/tenants.py 53%`
  - `src/api/admin/tokens.py 65%`
- Evidence:
  - https://github.com/Leeky1017/SS/actions/runs/20951885112

### 2026-01-13 10:20 Local coverage gate
- Command:
  - `python -m pytest -q --cov=src --cov-report=term-missing --cov-fail-under=80`
- Key output:
  - `Required test coverage of 80% reached. Total coverage: 80.44%`
  - `297 passed, 5 skipped`
- Evidence:
  - `tests/test_admin_api.py`
  - `tests/test_admin_jobs_api.py`

### 2026-01-13 10:21 PR preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
