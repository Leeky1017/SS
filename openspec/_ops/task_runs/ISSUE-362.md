# ISSUE-362

- Issue: #362
- Branch: `task/362-p5-13-spatial-output-tn-to`
- PR: https://github.com/Leeky1017/SS/pull/367

## Plan
- Add Phase 5.13 best-practice review + bilingual comments across TN01–TN10 and TO01–TO08.
- Upgrade TO* outputs to Stata 18 native tooling (`collect`/`etable`/`putdocx`/`putexcel`) and reduce SSC deps where feasible.
- Regenerate do-library index and verify via `ruff` + `pytest`.

## Runs
### 2026-01-12 bootstrap
- Command:
  - `gh issue create -t "[PHASE-5.13] Spatial+Output templates TN/TO: best practices + Stata 18 output upgrade" -b "..."`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 362 p5-13-spatial-output-tn-to`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/362`
  - `Worktree created: .worktrees/issue-362-p5-13-spatial-output-tn-to`

### 2026-01-12 do-library index regeneration
- Command: `python3 scripts/regenerate_do_library_index.py --library-dir assets/stata_do_library`
- Key output: `exit_code=0`
- Evidence: `assets/stata_do_library/DO_LIBRARY_INDEX.json`

### 2026-01-12 lint + tests
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `ruff: All checks passed!`
  - `pytest: 184 passed, 5 skipped in 10.36s`
- Evidence: (stdout)

### 2026-01-12 PR preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
- Evidence: (stdout)

### 2026-01-12 PR created
- Command: `gh pr create --title \"[PHASE-5.13] Spatial+Output templates TN/TO: best practices + native outputs (#362)\" --body \"Closes #362 ...\"`
- Key output: `https://github.com/Leeky1017/SS/pull/367`

### 2026-01-12 post-merge sync (controlplane)
- Command: `scripts/agent_controlplane_sync.sh`
- Key output:
  - `Updating f41e4b7..3216d32`
  - `Fast-forward`
- Evidence: (stdout)

### 2026-01-12 worktree cleanup (controlplane)
- Command: `scripts/agent_worktree_cleanup.sh 362 p5-13-spatial-output-tn-to`
- Key output:
  - `OK: cleaned worktree .worktrees/issue-362-p5-13-spatial-output-tn-to and local branch task/362-p5-13-spatial-output-tn-to`
- Evidence: (stdout)

### 2026-01-12 closeout (task card + Rulebook archive)
- Command:
  - `gh issue reopen 362`
  - `scripts/agent_worktree_setup.sh 362 p5-13-spatial-output-tn-to-closeout`
  - `git mv rulebook/tasks/issue-362-p5-13-spatial-output-tn-to rulebook/tasks/archive/2026-01-12-issue-362-p5-13-spatial-output-tn-to`
- Key output:
  - `Reopened issue Leeky1017/SS#362`
  - `Worktree created: .worktrees/issue-362-p5-13-spatial-output-tn-to-closeout`
- Evidence:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5.13__spatial-output-TN-TO.md`
  - `rulebook/tasks/archive/2026-01-12-issue-362-p5-13-spatial-output-tn-to`
