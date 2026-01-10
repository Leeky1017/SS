# ISSUE-315
- Issue: #315 https://github.com/Leeky1017/SS/issues/315
- Branch: task/315-prod-e2e-r043
- PR: https://github.com/Leeky1017/SS/pull/318
- Closeout PR: https://github.com/Leeky1017/SS/pull/320

## Plan
- Remove runtime FakeObjectStore wiring; enforce S3-only backend.
- Fail fast in production when S3 config missing (startup + /health/ready).
- Move FakeObjectStore to `tests/**` via injection; keep tests green.

## Runs
### 2026-01-10 Setup: Issue + worktree
- Command:
  - `gh issue create -t "[ROUND-01-PROD-A] PROD-E2E-R043: 移除 FakeObjectStore" -b "<body omitted>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "315" "prod-e2e-r043"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/315`
  - `Worktree created: .worktrees/issue-315-prod-e2e-r043`
  - `Branch: task/315-prod-e2e-r043`

### 2026-01-10 Validation: ruff + pytest (venv)
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `173 passed, 5 skipped`

### 2026-01-10 Preflight: roadmap + open PR overlap
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-10 Closeout: task card completion
- Command:
  - Open PR: https://github.com/Leeky1017/SS/pull/320
- Key output:
  - Task card `round-01-prod-a__PROD-E2E-R043.md` acceptance checklist marked complete
  - `## Completion` added with PR + run log reference
