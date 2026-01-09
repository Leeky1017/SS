# ISSUE-226
- Issue: #226
- Branch: task/226-ss-frontend-backend-alignment
- PR: Not created (git remote HTTPS to github.com:443 is unreachable from this environment)

## Goal
- Add a new OpenSpec spec `ss-frontend-backend-alignment` (spec + task cards only) that freezes the v1 frontend↔backend contract for redeem/token auth and Step 3 preview/patch/confirm, including the backend test gate.

## Status
- CURRENT: Spec + task cards drafted and validated; pending commit.

## Next Actions
- [x] Create spec `openspec/specs/ss-frontend-backend-alignment/spec.md` and task cards ALIGN-C001..C005.
- [x] Run `openspec validate --specs --strict --no-interactive`.
- [x] Create + validate Rulebook task `issue-226-ss-frontend-backend-alignment`.
- [ ] Commit changes with message containing `(#226)`.

## Decisions Made
- 2026-01-09: Redeem returns a non-rotating token (same task_code → same token); `expires_at` uses sliding expiration of 7 days.
- 2026-01-09: Redeem-created jobs require Bearer auth for all `/v1/jobs/{job_id}/...` routes; `POST /v1/jobs` remains but is disableable via `SS_V1_ENABLE_LEGACY_POST_JOBS`.
- 2026-01-09: Step 3 confirm is backend-gated (stage1 + open_unknowns) to prevent frontend bypass.

## Errors Encountered
- 2026-01-09: `git fetch origin main` hangs due to `github.com:443` connect timeouts (while `api.github.com` is reachable); worktree isolation was created from local `main` without remote sync.

## Runs
### 2026-01-09 Setup: GitHub issue
- Command:
  - `gh issue create -t "[ROUND-03-ALIGN-A] ALIGN-C000: ss-frontend-backend-alignment spec + task cards" -b "..."`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/226`
- Evidence:
  - N/A

### 2026-01-09 Setup: Worktree (local-only, no remote fetch)
- Command:
  - `git worktree add -b "task/226-ss-frontend-backend-alignment" ".worktrees/issue-226-ss-frontend-backend-alignment" main`
- Key output:
  - `Preparing worktree (new branch 'task/226-ss-frontend-backend-alignment')`
- Evidence:
  - N/A

### 2026-01-09 OpenSpec validation
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 24 passed, 0 failed (24 items)`
- Evidence:
  - N/A

### 2026-01-09 Rulebook task
- Command:
  - `rulebook task create issue-226-ss-frontend-backend-alignment`
  - `rulebook task validate issue-226-ss-frontend-backend-alignment`
- Key output:
  - `Task issue-226-ss-frontend-backend-alignment is valid`
- Evidence:
  - N/A
