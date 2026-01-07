# ISSUE-126

- Issue: #126
- Branch: task/126-ux-b001-inputs-upload-preview
- PR: https://github.com/Leeky1017/SS/pull/136

## Plan
- Add dataset upload endpoint + store under `inputs/`
- Write `inputs/manifest.json` + update `job.json` fingerprint
- Add preview endpoint (columns + sample rows)
- Cover happy path + key errors with tests

## Runs
### 2026-01-07 19:50 Setup: controlplane sync + worktree
- Command:
  - `git stash push -u -m "wip: stash untracked leftovers before issue-126"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 126 ux-b001-inputs-upload-preview`
- Key output:
  - `Saved working directory and index state On main: wip: stash untracked leftovers before issue-126`
  - `Already up to date.`
  - `Worktree created: .worktrees/issue-126-ux-b001-inputs-upload-preview`
  - `Branch: task/126-ux-b001-inputs-upload-preview`
- Evidence:
  - `.worktrees/issue-126-ux-b001-inputs-upload-preview/`

### 2026-01-07 19:50 Setup: rulebook task
- Command:
  - `rulebook task create issue-126-ux-b001-inputs-upload-preview`
  - `rulebook task validate issue-126-ux-b001-inputs-upload-preview`
- Key output:
  - `✅ Task issue-126-ux-b001-inputs-upload-preview created successfully`
  - `✅ Task issue-126-ux-b001-inputs-upload-preview is valid`
- Evidence:
  - `rulebook/tasks/issue-126-ux-b001-inputs-upload-preview/`

### 2026-01-07 20:01 Setup: python env
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... pandas ... python-multipart ... ruff ... pytest ...`
- Evidence:
  - `.venv/`

### 2026-01-07 20:02 Verify: ruff + pytest
- Command:
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `101 passed, 5 skipped in 4.39s`

### 2026-01-07 20:04 Deliver: preflight + PR
- Command:
  - `scripts/agent_pr_preflight.sh`
  - `git push -u origin HEAD`
  - `gh pr create --title "[ROUND-01-UX-A] UX-B001: 数据上传 + 数据预览（CSV/Excel/DTA） (#126)" --body "Closes #126 ..."`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
  - `https://github.com/Leeky1017/SS/pull/136`
