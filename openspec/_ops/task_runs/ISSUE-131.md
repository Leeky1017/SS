# ISSUE-131

- Issue: #131
- Branch: task/131-ux-spec-centralize
- PR: https://github.com/Leeky1017/SS/pull/132

## Plan
- Write a dedicated OpenSpec for production-readiness UX blockers
- Move UX blocker task cards into the new spec (more detailed)
- Remove old scattered task cards and update references

## Runs
### 2026-01-07 18:00 Setup: issue/worktree
- Command:
  - `gh issue create -t "[ROUND-01-UX-A] UX-S001: 集中 UX blockers 到独立 OpenSpec（移除散落 task cards）" -b "<body>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "131" "ux-spec-centralize"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/131`
  - `Worktree created: .worktrees/issue-131-ux-spec-centralize`
  - `Branch: task/131-ux-spec-centralize`

### 2026-01-07 18:00 Setup: rulebook task
- Command:
  - `rulebook task create issue-131-ux-spec-centralize`
  - `rulebook task validate issue-131-ux-spec-centralize`
- Key output:
  - `✅ Task issue-131-ux-spec-centralize created successfully`
  - `✅ Task issue-131-ux-spec-centralize is valid`
- Evidence:
  - `rulebook/tasks/issue-131-ux-spec-centralize/`

### 2026-01-07 18:32 Build: venv + deps
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... ruff ... pytest ...`
- Evidence:
  - `.venv/`

### 2026-01-07 18:32 Validate: ruff + pytest
- Command:
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `95 passed, 5 skipped in 3.66s`

### 2026-01-07 18:32 Spec: centralize UX blockers
- Evidence:
  - `openspec/specs/ss-ux-loop-closure/spec.md`
  - `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B001.md`
  - `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B002.md`
  - `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B003.md`
  - Removed old scattered task cards:
    - `openspec/specs/ss-api-surface/task_cards/round-01-ux-a__UX-B001.md`
    - `openspec/specs/ss-llm-brain/task_cards/round-01-ux-a__UX-B002.md`
    - `openspec/specs/ss-stata-runner/task_cards/round-01-ux-a__UX-B003.md`

### 2026-01-07 18:35 Deliver: preflight + PR
- Command:
  - `scripts/agent_pr_preflight.sh`
  - `gh pr create --title "[ROUND-01-UX-A] UX-S001: 集中 UX blockers OpenSpec (#131)" --body "Closes #131 ..."`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
  - `https://github.com/Leeky1017/SS/pull/132`
