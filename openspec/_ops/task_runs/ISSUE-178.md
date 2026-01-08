# ISSUE-178
- Issue: #178
- Branch: task/178-p52-core-t21-t50
- PR: <fill-after-created>

## Goal
- Enhance core templates `T21`–`T50` per Phase 5.2: best-practice upgrades + decision record, replace SSC deps with Stata 18 native where feasible, stronger error handling (warn/fail + `SS_RC`), bilingual comments, output upgrades.

## Status
- CURRENT: Set up worktree + run log; begin template upgrades for `T21`–`T50`.

## Next Actions
- [ ] Add Rulebook task notes + checklist for Issue #178
- [ ] Update `assets/stata_do_library/do/T21`–`T50` (+ meta) to remove SSC deps (estout) and upgrade outputs
- [ ] Run `ruff check .` and `pytest -q`, then `scripts/agent_pr_preflight.sh`
- [ ] Open PR with `Closes #178`, enable auto-merge, and backfill PR link here

## Decisions Made
- 2026-01-08: Split Phase 5.2 (core) and Phase 5.3 (data-prep) into separate Issues/PRs to keep reviewable scope and independent dependencies.

## Errors Encountered
- 2026-01-08: `gh auth status` timed out once → retried and succeeded.
- 2026-01-08: Local `main` diverged from `origin/main` → reset local `main` to `origin/main` after branching `backup/local-main-4b2c34c`.

## Runs
### 2026-01-08 Setup: GitHub auth + Issue + worktree
- Command:
  - `gh auth status`
  - `gh issue create -t "[P5.2] Template content enhancement: Core (T21–T50)" -b "<...>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "178" "p52-core-t21-t50"`
- Key output:
  - `Logged in to github.com account Leeky1017`
  - `https://github.com/Leeky1017/SS/issues/178`
  - `Worktree created: .worktrees/issue-178-p52-core-t21-t50`
- Evidence:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5.2__core-T21-T50.md`

### 2026-01-08 Validate: venv + ruff + pytest
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -U pip`
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `136 passed, 5 skipped`
- Evidence:
  - `.worktrees/issue-178-p52-core-t21-t50/.venv/` (local venv for this worktree only)

### 2026-01-08 Preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
- Evidence:
  - `openspec/_ops/task_runs/ISSUE-178.md`

### 2026-01-08 Preflight (post-commit)
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
- Evidence:
  - `openspec/_ops/task_runs/ISSUE-178.md`
