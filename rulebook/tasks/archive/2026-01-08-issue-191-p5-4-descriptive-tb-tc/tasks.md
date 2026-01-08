## 1. Implementation
- [ ] 1.1 Add best-practice review record to TB02-TB10 and TC01-TC10
- [ ] 1.2 Replace SSC deps where feasible (prefer Stata 18 built-ins; add graceful fallback if parity not feasible)
- [ ] 1.3 Strengthen validation + error handling (explicit `SS_RC`; no silent `capture` on critical steps)
- [ ] 1.4 Align affected `do/meta/*.meta.json` dependencies/inputs with implemented behavior

## 2. Testing
- [ ] 2.1 `ruff check .`
- [ ] 2.2 `pytest -q`

## 3. Documentation / Evidence
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-191.md` with key commands + outputs
- [ ] 3.2 Link any reports/artifacts paths from runs

