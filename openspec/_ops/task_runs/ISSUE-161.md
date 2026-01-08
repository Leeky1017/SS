# ISSUE-161

- Issue: #161
- Branch: task/161-multi-dataset-inputs-roles
- PR: https://github.com/Leeky1017/SS/pull/166

## Goal
- Support uploading 2+ dataset files per job with explicit roles and a deterministic inputs fingerprint.

## Status
- CURRENT: Multi-dataset upload implemented + tests green; preparing PR.

## Next Actions
- [x] Extend inputs upload API to accept 2+ files and per-file roles
- [x] Persist `inputs/manifest.json` with `dataset_key` + `role` + `rel_path` + `fingerprint`
- [x] Make `job.json.inputs.fingerprint` deterministic across ordering
- [x] Add/adjust tests for multi-file + backward-compatible single-file path
- [ ] Run `scripts/agent_pr_preflight.sh`, open PR, enable auto-merge

## Decisions Made
- 2026-01-08: Prefer manifest `datasets[]` as the canonical multi-input record; keep reads compatible with existing single-file manifest shape.

## Errors Encountered
- 2026-01-08: `scripts/agent_controlplane_sync.sh` failed due to untracked rulebook task created on controlplane `main` → resolved via `git stash -u` and applying the stash in the worktree.

## Runs
### 2026-01-08 Setup: gh auth + repo remotes
- Command:
  - `gh auth status`
  - `git remote -v`
- Key output:
  - `Logged in to github.com account Leeky1017`
  - `origin https://github.com/Leeky1017/SS.git (fetch)`
- Evidence:
  - Issue: https://github.com/Leeky1017/SS/issues/161

### 2026-01-08 Setup: create Issue #161
- Command:
  - `gh issue create -t "[PHASE-03.1] Multi-dataset inputs + roles" -b "<body>"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/161`
- Evidence:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-3.1__multi-dataset-inputs-and-roles.md`

### 2026-01-08 Setup: worktree
- Command:
  - `git stash push -u -m "wip: rulebook task issue-161"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 161 multi-dataset-inputs-roles`
  - `git stash pop stash@{0}`
- Key output:
  - `Worktree created: .worktrees/issue-161-multi-dataset-inputs-roles`
  - `Branch: task/161-multi-dataset-inputs-roles`
- Evidence:
  - `.worktrees/issue-161-multi-dataset-inputs-roles/`

### 2026-01-08 02:07 Setup: python env
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... ruff ... pytest ... mypy ...`
- Evidence:
  - `.venv/`

### 2026-01-08 02:10 Verify: ruff
- Command:
  - `.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`

### 2026-01-08 02:11 Verify: pytest
- Command:
  - `.venv/bin/pytest -q`
- Key output:
  - `124 passed, 5 skipped`

### 2026-01-08 02:12 Verify: mypy
- Command:
  - `.venv/bin/mypy`
- Key output:
  - `Success: no issues found in 95 source files`

### 2026-01-08 02:13 Deliver: preflight + push + PR
- Command:
  - `scripts/agent_pr_preflight.sh`
  - `git push -u origin HEAD`
  - `gh pr create --title "[PHASE-03.1] Multi-dataset inputs + roles (#161)" --body "Closes #161 ..."`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
  - `https://github.com/Leeky1017/SS/pull/166`
