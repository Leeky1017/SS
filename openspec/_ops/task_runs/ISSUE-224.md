# ISSUE-224
- Issue: #224
- Branch: task/224-ss-frontend-desktop-pro-auth
- PR: (not created yet)

## Goal
- Update `ss-frontend-desktop-pro` spec + task cards to make task-code redeem the default production entry flow, and to define token persistence + Authorization header behavior (with dev-only fallback to `POST /v1/jobs` gated by `VITE_REQUIRE_TASK_CODE`).

## Status
- CURRENT: Drafting spec/task-card updates for task-code redeem + auth token.

## Next Actions
- [ ] Update `openspec/specs/ss-frontend-desktop-pro/spec.md` with redeem flow, `VITE_REQUIRE_TASK_CODE`, token storage + auth header rules.
- [ ] Update FE-C002 and FE-C003 task cards with the new responsibilities + acceptance items.
- [ ] Run `openspec validate --specs --strict --no-interactive` and `scripts/agent_pr_preflight.sh`.
- [ ] Open PR (Closes #224), enable auto-merge, and update this run log with the PR link.

## Decisions Made
- 2026-01-09: Production entry path uses `POST /v1/task-codes/redeem` returning `{job_id, token}`; fallback to `POST /v1/jobs` is dev-only and gated by `VITE_REQUIRE_TASK_CODE`.
- 2026-01-09: Token persistence keys are fixed: `ss.auth.v1.{job_id}` and `ss.last_job_id`.
- 2026-01-09: All `/v1/**` requests attach `Authorization: Bearer <token>` when token exists; on 401/403 the client clears the token and prompts re-redeem.

## Errors Encountered
- None

## Runs
### 2026-01-09 Setup: GitHub issue + worktree
- Command:
  - `gh auth status`
  - `gh issue create -t "[ROUND-03-FE-A] FE-C007: ss-frontend-desktop-pro task-code redeem + token auth" -b "..."`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "224" "ss-frontend-desktop-pro-auth"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/224`
  - `Worktree created: .worktrees/issue-224-ss-frontend-desktop-pro-auth`
- Evidence:
  - N/A

### 2026-01-09 Setup: Rulebook task
- Command:
  - `rulebook task create issue-224-ss-frontend-desktop-pro-auth`
- Key output:
  - `Location: rulebook/tasks/issue-224-ss-frontend-desktop-pro-auth/`
- Evidence:
  - N/A

### 2026-01-09 OpenSpec validation
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 23 passed, 0 failed (23 items)`
- Evidence:
  - N/A

### 2026-01-09 Rulebook validation
- Command:
  - `rulebook task validate issue-224-ss-frontend-desktop-pro-auth`
- Key output:
  - `Task issue-224-ss-frontend-desktop-pro-auth is valid`
  - `Warnings: No spec files found (specs/*/spec.md)`
- Evidence:
  - N/A

### 2026-01-09 Preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
- Evidence:
  - N/A
