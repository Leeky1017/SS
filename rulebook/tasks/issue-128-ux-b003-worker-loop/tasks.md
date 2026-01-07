## 1. Implementation
- [ ] 1.1 Worker loads job + asserts `llm_plan`
- [ ] 1.2 Worker loads inputs manifest from `inputs.manifest_rel_path`
- [ ] 1.3 Worker generates `stata.do` via `DoFileGenerator`
- [ ] 1.4 Worker selects runner via `SS_STATA_CMD` (Local vs Fake)
- [ ] 1.5 Worker persists success/failure evidence under `runs/<run_id>/`

## 2. Testing
- [ ] 2.1 Success path: artifacts include `stata.do` + `stata.log` + `run.meta.json` + export table
- [ ] 2.2 Failure path: pre-run errors produce `run.error.json` + evidence artifacts
- [ ] 2.3 User journey tests download exported table via artifacts API

## 3. Delivery
- [ ] 3.1 Update run log: `openspec/_ops/task_runs/ISSUE-128.md`
- [ ] 3.2 Run `.venv/bin/ruff check .` and `.venv/bin/pytest -q`
- [ ] 3.3 Open PR with `Closes #128` and enable auto-merge
