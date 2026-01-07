# ISSUE-83

- Issue: #83
- Branch: task/83-api-versioning
- PR: https://github.com/Leeky1017/SS/pull/87

## Plan
- Serve all HTTP routes under `/v1`
- Define a deprecation policy (headers + schedule)
- Document version lifecycle and support windows
- Add tests covering coexistence during deprecation

## Runs
### 2026-01-07 controlplane sync + worktree setup
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "83" "api-versioning"`
- Key output:
  - `Worktree created: .worktrees/issue-83-api-versioning`
  - `Branch: task/83-api-versioning`

### 2026-01-07 ruff + pytest + openspec validate
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `All checks passed!`
  - `63 passed`
  - `Totals: 16 passed, 0 failed (16 items)`

### 2026-01-07 PR preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-07 PR + auto-merge
- Command:
  - `scripts/agent_pr_automerge_and_sync.sh --pr 87 --no-create`
- Key output:
  - `OK: merged PR #87 and synced controlplane main`
