# ISSUE-96

- Issue: #96
- Branch: task/96-job-store-sharding
- PR: <fill-after-created>

## Plan
- Define sharded job directory scheme and compatibility rules
- Update job workspace path resolution to support sharded + legacy layouts
- Add tests for sharded + legacy behavior and document ops implications

## Runs
### 2026-01-07 00:00 Task start
- Command:
  - `gh issue create -t "[SS-AUDIT-SCALABILITY] Job store sharding strategy" -b "<...>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 96 job-store-sharding`
- Key output:
  - `Issue: https://github.com/Leeky1017/SS/issues/96`
  - `Worktree created: .worktrees/issue-96-job-store-sharding`
- Evidence:
  - `openspec/specs/ss-audit-remediation/task_cards/scalability__job-store-sharding.md`
  - `Audit/02_Deep_Dive_Analysis.md`
  - `openspec/specs/ss-job-contract/spec.md`

### 2026-01-07 00:10 Local tooling setup
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... pytest ... ruff ...`

### 2026-01-07 00:12 Lint
- Command:
  - `.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`

### 2026-01-07 00:12 Tests
- Command:
  - `.venv/bin/pytest -q`
- Key output:
  - `68 passed`
