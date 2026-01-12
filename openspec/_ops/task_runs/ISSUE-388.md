# ISSUE-388
- Issue: #388
- Branch: task/388-deploy-ready-r030
- PR: <fill>

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
- Evidence: `rulebook/tasks/issue-388-deploy-ready-r030/`

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
- Evidence: `rulebook/tasks/issue-388-deploy-ready-r030/evidence/do_template_data_shape_matrix.md`

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
