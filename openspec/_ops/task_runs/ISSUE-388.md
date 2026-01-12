# ISSUE-388
- Issue: #388
- Branch: task/388-deploy-ready-r030
- PR: https://github.com/Leeky1017/SS/pull/395

## Plan
- Add wide/long/panel meta coverage for audited templates.
- Add minimal smoke/audit regression path for shape-sensitive templates.
- Update data-shape capability matrix and evidence pointers.

## Runs
### 2026-01-12 15:05 Setup (Issue)
- Command: `gh issue create -t "[DEPLOY-READY] DEPLOY-READY-R030: 补充缺失的 do-template（宽表/长表/面板数据）" -b "..."`
- Key output: `https://github.com/Leeky1017/SS/issues/388`
- Evidence: `openspec/specs/ss-deployment-docker-readiness/task_cards/remediation__DEPLOY-READY-R030.md`

### 2026-01-12 15:06 Worktree
- Command: `scripts/agent_worktree_setup.sh "388" "deploy-ready-r030"`
- Key output: `Worktree created: .worktrees/issue-388-deploy-ready-r030`
- Evidence: `.worktrees/issue-388-deploy-ready-r030`

### 2026-01-12 15:07 Rulebook task
- Command:
  - `rulebook task create issue-388-deploy-ready-r030`
  - `rulebook task validate issue-388-deploy-ready-r030`
- Key output:
  - `Task issue-388-deploy-ready-r030 created successfully`
  - `Task issue-388-deploy-ready-r030 is valid`
- Evidence: `rulebook/tasks/archive/2026-01-12-issue-388-deploy-ready-r030/`

### 2026-01-12 15:12 Wide/long/panel tag signals (meta)
- Command: `python3 -c "<count tags wide/long/panel in do/meta/*.meta.json>"`
- Key output:
  - `before: wide=1 long=1 panel=39`
  - `after:  wide=2 long=3 panel=39`
- Evidence:
  - `assets/stata_do_library/do/meta/T14_ttest_paired.meta.json`
  - `assets/stata_do_library/do/meta/T30_panel_setup_check.meta.json`
  - `assets/stata_do_library/do/meta/T31_panel_fe_basic.meta.json`

### 2026-01-12 15:18 Matrix update (evidence)
- Evidence: `rulebook/tasks/archive/2026-01-12-issue-388-deploy-ready-r030/evidence/do_template_data_shape_matrix.md`

### 2026-01-12 15:21 Local checks (ruff + pytest)
- Command:
  - `python3 -m venv .venv && .venv/bin/python -m pip install -U pip`
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `187 passed, 5 skipped`

### 2026-01-12 15:22 PR preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-12 15:23 PR created
- Command: `gh pr create --title "[DEPLOY-READY] DEPLOY-READY-R030: close do-template data-shape gaps (#388)" --body "Closes #388 ..."`
- Key output: `https://github.com/Leeky1017/SS/pull/395`

### 2026-01-12 15:24 Enable auto-merge
- Command: `gh pr merge --auto --squash 395`
- Key output: `will be automatically merged via squash when all requirements are met`

### 2026-01-12 15:29 Auto-merge unblock (branch behind)
- Command:
  - `git fetch origin main && git rebase origin/main`
  - `git push --force-with-lease`
- Key output: `PR auto-merge required branch update (mergeStateStatus=BEHIND)`

### 2026-01-12 15:32 Checks green + merged
- Command:
  - `gh pr checks --watch 395`
  - `gh pr view 395 --json mergedAt,state`
- Key output:
  - `ci: success`
  - `merge-serial: success`
  - `openspec-log-guard: success`
  - `state=MERGED mergedAt=2026-01-12T07:32:12Z`

### 2026-01-12 15:33 Rulebook archive
- Command: `rulebook task archive issue-388-deploy-ready-r030`
- Key output: `Task issue-388-deploy-ready-r030 archived successfully`
- Evidence: `rulebook/tasks/archive/2026-01-12-issue-388-deploy-ready-r030/`
