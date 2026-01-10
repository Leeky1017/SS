## 1. Harness + Evidence
- [ ] 1.1 Add smoke-suite manifest for TI01–TI11 + TJ01–TJ06
- [ ] 1.2 Run Stata 18 smoke suite and capture report + per-template artifacts

## 2. Template Fixes (TI01–TI11, TJ01–TJ06)
- [ ] 2.1 Fix runtime errors and fragile assumptions
- [ ] 2.2 Normalize anchors to `SS_EVENT|k=v` (remove legacy `SS_*:...`)
- [ ] 2.3 Ensure explicit `warn/fail` with `SS_RC` for survival/multivariate failure modes

## 3. Verification + Delivery
- [ ] 3.1 Re-run smoke suite to 0 fail; run `ruff check .` + `pytest -q` + `openspec validate`
- [ ] 3.2 Update `openspec/_ops/task_runs/ISSUE-271.md` with commands/output and PR link

