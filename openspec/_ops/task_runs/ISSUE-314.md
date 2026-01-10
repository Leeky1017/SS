# ISSUE-314
- Issue: #314 https://github.com/Leeky1017/SS/issues/314
- Branch: task/314-prod-e2e-r002-redeem-only
- PR: <fill-after-created>

## Goal
- Make `POST /v1/task-codes/redeem` the only v1 job creation entrypoint by removing legacy `POST /v1/jobs` and its config toggle `v1_enable_legacy_post_jobs`, and updating all callers.

## Status
- CURRENT: Legacy `POST /v1/jobs` removed; callers updated; local ruff/pytest green; preparing PR.

## Next Actions
- [x] Remove legacy `POST /v1/jobs` route and any related auth guards.
- [x] Remove `v1_enable_legacy_post_jobs` config and update references.
- [x] Update any tests/scripts/docs that call `POST /v1/jobs` to use `POST /v1/task-codes/redeem`.
- [x] Run `ruff check .` and `pytest -q`, record key outputs.
- [ ] Run `scripts/agent_pr_preflight.sh`, open PR, enable auto-merge, and verify `MERGED`.
- [ ] Sync controlplane `main` and cleanup worktree.

## Decisions Made
- 2026-01-10: Remove the legacy endpoint entirely (no compatibility toggle) to enforce a single audited job creation chain.

## Errors Encountered
- (none)

## Runs
### 2026-01-10 Setup: GitHub gates + worktree
- Command:
  - `gh auth status`
  - `git remote -v`
  - `gh issue create -t "[ROUND-01-PROD-A] PROD-E2E-R002: 只允许 task-code redeem 创建 job（移除 legacy POST /v1/jobs）" -b "<body omitted>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "314" "prod-e2e-r002-redeem-only"`
- Key output:
  - `Logged in to github.com account Leeky1017`
  - `origin https://github.com/Leeky1017/SS.git (fetch/push)`
  - `https://github.com/Leeky1017/SS/issues/314`
  - `Worktree created: .worktrees/issue-314-prod-e2e-r002-redeem-only`
  - `Branch: task/314-prod-e2e-r002-redeem-only`
- Evidence:
  - (this file)

### 2026-01-10 Validation: remove legacy entry + ruff + pytest
- Command:
  - `rg -n "@router\\.post\\(\\\"/jobs\\\"\\)" src/api || echo "no @router.post('/jobs') matches"`
  - `rg -n "SS_V1_ENABLE_LEGACY_POST_JOBS|v1_enable_legacy_post_jobs" src || echo "no legacy post jobs config matches"`
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `no @router.post('/jobs') matches`
  - `no legacy post jobs config matches`
  - `All checks passed!`
  - `169 passed, 5 skipped`
- Evidence:
  - (this file)
