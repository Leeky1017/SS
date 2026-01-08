## 1. Implementation
- [ ] 1.1 Add smoke-suite fixtures for TA01-TA14
- [ ] 1.2 Extend smoke-suite manifest entries for TA01-TA14 params + deps
- [ ] 1.3 Normalize TA01-TA14 anchors to `SS_*|k=v` (remove legacy `SS_*:`)
- [ ] 1.4 Add fail-fast SSC dependency checks (missing → `SS_RC` + `exit 199`)
- [ ] 1.5 Fix runtime errors surfaced by fixtures (missing vars, empty sample, type mismatch)

## 2. Testing
- [ ] 2.1 `python3 assets/stata_do_library/DO_LINT_RULES.py --path assets/stata_do_library/do --output /tmp/do_lint_report_165.json`
- [ ] 2.2 `ruff check .`
- [ ] 2.3 `pytest -q`

## 3. Documentation / Evidence
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-165.md` with commands + key outputs
- [ ] 3.2 Link smoke-suite report + any artifacts paths from runs

