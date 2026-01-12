# ISSUE-370
- Issue: #370
- Branch: task/370-deploy-ready-r002
- PR: https://github.com/Leeky1017/SS/pull/385

## Goal
- DEPLOY-READY-R002: audit do-template library output format support based on `assets/stata_do_library/` (meta + template implementations), and provide remediation input for DEPLOY-READY-R031 (unified output formatter).

## Plan
- Audit `do/meta/*.meta.json` `outputs[]` and deps.
- Sample templates for output implementation patterns (csv/xlsx/dta/docx/pdf/log/do).
- Produce capability matrix + gaps + artifact naming findings.

## Runs
### 2026-01-12 13:18 Bootstrap (spec-first)
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "370" "deploy-ready-r002"`
  - `rulebook task create issue-370-deploy-ready-r002`
  - `rulebook task validate issue-370-deploy-ready-r002`
- Key output:
  - `Worktree: .worktrees/issue-370-deploy-ready-r002`
  - `Branch: task/370-deploy-ready-r002`
  - `Task: rulebook/tasks/issue-370-deploy-ready-r002/`
- Evidence:
  - `openspec/specs/ss-deployment-docker-readiness/task_cards/audit__DEPLOY-READY-R002.md`
  - `rulebook/tasks/issue-370-deploy-ready-r002/proposal.md`
  - `rulebook/tasks/issue-370-deploy-ready-r002/tasks.md`

### 2026-01-12 13:34 Audit meta outputs[] + dependencies[]
- Command:
  - `python3 scripts/audit_do_template_output_formats.py`
- Key output:
  - `meta_files=310`
  - `TEMPLATE_COUNT_BY_EXT: log=310 csv=288 dta=252 docx=15 pdf=1 xlsx=1 (png=110)`
  - `WANTED_EXTS: csv=288 xlsx=1 dta=252 docx=15 pdf=1 log=310 do=0`
  - `docx_templates_missing_dep_putdocx=9 (T21 T22 T23 T24 T31 T32 T33 T34 T35)`
  - `pdf_report_templates=0; pdf_figure_templates=1 (TO07)`
  - `dependency_entries=303; SOURCE_COUNT built-in=263 ssc=26 stata=14`
- Evidence:
  - `scripts/audit_do_template_output_formats.py`
  - `assets/stata_do_library/do/meta/*.meta.json`

### 2026-01-12 14:17 Sample template output implementations (do/*.do)
- Command:
  - `rg -l -F 'log using \"result.log\"' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l -F 'export delimited' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l -F 'putdocx' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l -F 'putpdf' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l -F 'putexcel' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l -F 'export excel' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l -F 'outsheet' assets/stata_do_library/do/*.do | wc -l`
  - `rg -l -P 'graph\\s+export\\s+\"[^\"]+\\.pdf\"' assets/stata_do_library/do/*.do | wc -l`
  - `rg -n -F 'export delimited using \"table_T01_desc_stats.csv\"' assets/stata_do_library/do/T01_desc_overview.do`
  - `rg -n -F 'save \"data_T03_filtered_data.dta\"' assets/stata_do_library/do/T03_filter_and_sample.do`
  - `rg -n -F 'putdocx save \"table_T21_paper.docx\"' assets/stata_do_library/do/T21_ols_with_interaction.do`
  - `rg -n -F 'putexcel set \"table_TO04_results.xlsx\"' assets/stata_do_library/do/TO04_putexcel.do`
  - `rg -n -F 'graph export \"fig_TO07_scatter.pdf\"' assets/stata_do_library/do/TO07_graph_export.do`
- Key output:
  - `log using "result.log"`: `310` templates
  - `export delimited` (CSV): `288` templates
  - `putdocx` (DOCX): `15` templates
  - `putpdf` (PDF report): `0` templates
  - `putexcel` (XLSX): `1` template
  - `graph export ... .pdf` (PDF figure): `1` template (`TO07`)
- Evidence:
  - `assets/stata_do_library/do/T01_desc_overview.do`
  - `assets/stata_do_library/do/T03_filter_and_sample.do`
  - `assets/stata_do_library/do/T21_ols_with_interaction.do`
  - `assets/stata_do_library/do/TO04_putexcel.do`
  - `assets/stata_do_library/do/TO07_graph_export.do`

### 2026-01-12 14:21 Write audit report (capability matrix + gaps)
- Command:
  - `cat rulebook/tasks/issue-370-deploy-ready-r002/evidence/do_template_output_formats_audit.md`
- Key output:
  - `do-template outputs capability matrix completed (csv/xlsx/dta/docx/pdf/log/do)`
  - `Word/PDF strategy + gaps documented for DEPLOY-READY-R031`
  - `Artifact kind/naming inconsistencies identified with remediation suggestions`
- Evidence:
  - `rulebook/tasks/issue-370-deploy-ready-r002/evidence/do_template_output_formats_audit.md`

### 2026-01-12 14:25 Local checks (ruff + pytest)
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -U pip`
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `184 passed, 5 skipped in 9.04s`

### 2026-01-12 14:26 PR preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-12 14:30 PR created
- Command:
  - `gh pr create --title "[DEPLOY-READY-R002] Audit do-template output formats (#370)" --body "Closes #370 ..."`
- Key output:
  - `PR: https://github.com/Leeky1017/SS/pull/385`

### 2026-01-12 14:31 Enable auto-merge
- Command:
  - `gh pr merge --auto --squash 385`
- Key output:
  - `will be automatically merged via squash when all requirements are met`
