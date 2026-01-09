# ISSUE-231
- Issue: #231
- Branch: task/231-align-c002-redeem-auth
- PR: <fill-after-created>

## Goal
- Implement the v1 redeem + bearer auth backend surface (ALIGN-C001..C003): freeze contract, add `POST /v1/task-codes/redeem`, persist/validate job tokens, and enforce stable auth/error behavior on `/v1/jobs/{job_id}/...`.

## Status
- CURRENT: Implementation + local validation complete; ready to open PR and enable auto-merge.

## Next Actions
- [x] Freeze v1 contract in `openspec/specs/ss-frontend-backend-alignment/spec.md` (no TODO/TBD).
- [x] Implement redeem + token storage/validation with sliding expiration.
- [x] Enforce bearer auth on `/v1/jobs/{job_id}/**` and gate `POST /v1/jobs` via `SS_V1_ENABLE_LEGACY_POST_JOBS`.
- [x] Run `ruff check .` and `pytest -q` and record outputs.
- [ ] Open PR (Closes #231) and enable auto-merge.

## Decisions Made
- 2026-01-09: Implement token auth as a job-scoped Bearer token stored in the job store, with idempotent redeem and sliding 7-day expiration.

## Errors Encountered
- None.

## Runs
### 2026-01-09 Setup: GitHub issue
- Command:
  - `gh issue create -t "[ROUND-03-CLI-B] ALIGN-C002: redeem + token auth (C001-003)" -b "..."`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/231`
- Evidence:
  - N/A

### 2026-01-09 Setup: Worktree
- Command:
  - `scripts/agent_worktree_setup.sh "231" "align-c002-redeem-auth"`
- Key output:
  - `Worktree created: .worktrees/issue-231-align-c002-redeem-auth`
- Evidence:
  - N/A

### 2026-01-09 OpenSpec validation
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 25 passed, 0 failed (25 items)`
- Evidence:
  - N/A

### 2026-01-09 Local lint (venv)
- Command:
  - `python3 -m venv .venv && .venv/bin/pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`
- Evidence:
  - N/A

### 2026-01-09 Local tests (venv)
- Command:
  - `.venv/bin/pytest -q`
- Key output:
  - `144 passed, 5 skipped`
- Evidence:
  - N/A
