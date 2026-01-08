## 1. Implementation
- [ ] 1.1 Add best-practice review record to TD01-TD06, TD10, TD12 and TE01-TE10
- [ ] 1.2 Replace SSC deps where feasible (prefer Stata 18 built-ins; keep only when no substitute exists)
- [ ] 1.3 Strengthen validation + error handling (explicit `SS_RC`; cover common regression failure modes)
- [ ] 1.4 Align affected `do/meta/*.meta.json` dependencies with implemented behavior

## 2. Testing
- [ ] 2.1 `ruff check .`
- [ ] 2.2 `pytest -q`

## 3. Documentation / Evidence
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-192.md` with key commands + outputs
- [ ] 3.2 Link any reports/artifacts paths from runs

