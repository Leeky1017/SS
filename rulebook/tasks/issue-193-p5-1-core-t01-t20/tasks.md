## 1. Implementation
- [ ] 1.1 Update task card metadata (Issue link) + run log skeleton
- [ ] 1.2 Add per-template best-practice review record for T01–T20
- [ ] 1.3 Replace SSC `estout/esttab` usage in T19/T20 with Stata 18 native output (`putdocx`)
- [ ] 1.4 Add bilingual comments for key steps across T01–T20
- [ ] 1.5 Ensure warn/fail paths emit structured `SS_RC` where needed

## 2. Testing
- [ ] 2.1 Run `python assets/stata_do_library/DO_LINT_RULES.py --path assets/stata_do_library/do --output lint_report.json` (or scoped run) and record key output
- [ ] 2.2 Run `ruff check .` and record key output
- [ ] 2.3 Run `pytest -q` and record key output

## 3. Documentation
- [ ] 3.1 Update run log `openspec/_ops/task_runs/ISSUE-193.md` with evidence + PR link
- [ ] 3.2 (If needed) document any remaining SSC exceptions in review records
