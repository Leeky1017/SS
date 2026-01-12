# ISSUE-372
- Issue: #372
- Branch: task/372-deploy-ready-r001
- PR: <fill-after-created>

## Plan
- Audit `assets/stata_do_library/do/` + `do/meta/*.meta.json` for wide/long/panel requirements.
- Produce an auditable capability matrix with per-conclusion template evidence pointers.
- Map gaps/risks to remediation card DEPLOY-READY-R030.

## Runs
### 2026-01-12 00:00 Setup
- Command: `gh issue create -t "[DEPLOY-READY] DEPLOY-READY-R001: 审计 do-template 库的数据处理能力（宽表/长表/面板数据）" -b "..."`
- Key output: `https://github.com/Leeky1017/SS/issues/372`
- Evidence: `openspec/specs/ss-deployment-docker-readiness/task_cards/audit__DEPLOY-READY-R001.md`

### 2026-01-12 00:01 Worktree
- Command: `scripts/agent_worktree_setup.sh "372" "deploy-ready-r001"`
- Key output: `Worktree created: .worktrees/issue-372-deploy-ready-r001`
- Evidence: `.worktrees/issue-372-deploy-ready-r001`

### 2026-01-12 00:02 Rulebook task
- Command:
  - `rulebook task create issue-372-deploy-ready-r001`
  - `rulebook task validate issue-372-deploy-ready-r001`
- Key output:
  - `Task issue-372-deploy-ready-r001 created successfully`
  - `Task issue-372-deploy-ready-r001 is valid (warnings: no specs)`
- Evidence: `rulebook/tasks/issue-372-deploy-ready-r001/`

### 2026-01-12 00:03 Library inventory counts
- Command:
  - `ls assets/stata_do_library/do/*.do | wc -l`
  - `ls assets/stata_do_library/do/meta/*.meta.json | wc -l`
- Key output:
  - `310`
  - `310`
- Evidence: `assets/stata_do_library/do/`

### 2026-01-12 00:04 Wide/long/panel signals (meta + code)
- Command:
  - `python3 -c "<count tags: panel/wide/long + family panel>"`
  - `rg -l '\\bxtset\\b' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l '\\btsset\\b' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l '\\breshape\\b' assets/stata_do_library/do/*.do | wc -l`
- Key output:
  - `tag_panel=39 family_panel=14 tag_wide=1 tag_long=1`
  - `xtset=51 tsset=30 reshape=12`

### 2026-01-12 00:05 Evidence pointers (templates inspected)
- Evidence:
  - `assets/stata_do_library/do/T01_desc_overview.do`
  - `assets/stata_do_library/do/T06_reshape_wide_long.do`
  - `assets/stata_do_library/do/T14_ttest_paired.do`
  - `assets/stata_do_library/do/T30_panel_setup_check.do`
  - `assets/stata_do_library/do/T31_panel_fe_basic.do`
  - `assets/stata_do_library/do/TA06_panel_balance.do`
  - `assets/stata_do_library/do/includes/ss_smart_xtset.ado`
  - `assets/stata_do_library/do/meta/T06_reshape_wide_long.meta.json`
  - `assets/stata_do_library/do/meta/T30_panel_setup_check.meta.json`

### 2026-01-12 00:06 Capability matrix report
- Evidence: `rulebook/tasks/issue-372-deploy-ready-r001/evidence/do_template_data_shape_audit.md`

### 2026-01-12 00:07 Local checks (ruff + pytest)
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -U pip`
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `184 passed, 5 skipped`
