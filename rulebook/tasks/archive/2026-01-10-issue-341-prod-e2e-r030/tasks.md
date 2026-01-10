# Tasks: issue-341-prod-e2e-r030

- [ ] Define structured plan-freeze error model (error_code + missing + next_action)
- [ ] Enforce plan-freeze gate for v1 draft blockers + template required params
- [ ] Add unit tests for missing blockers/params and success after fix
- [ ] Add integration tests for `/v1/jobs/{job_id}/plan/freeze` missing-param scenarios
- [ ] Run `ruff check .` and `pytest -q`; record in `openspec/_ops/task_runs/ISSUE-341.md`
- [ ] Open PR with `Closes #341` and enable auto-merge

