## 1. Implementation
- [x] 1.1 Audit `do/meta/*.meta.json` `outputs[]` + `dependencies[]`
- [x] 1.2 Sample-audit `do/*.do` output implementations (`putdocx`/`putpdf`/`export excel`/`outsheet`/`export delimited`/`save`)
- [x] 1.3 Write audit report: capability matrix + evidence + gaps
- [ ] 1.4 Update task card: Issue link + acceptance checklist + completion section

## 2. Verification
- [x] 2.1 Reproducible audit commands recorded in run log
- [x] 2.2 Local checks: `ruff check .` and `pytest -q`

## 3. Delivery
- [x] 3.1 Update `openspec/_ops/task_runs/ISSUE-370.md`
- [ ] 3.2 `scripts/agent_pr_preflight.sh` + PR + auto-merge
