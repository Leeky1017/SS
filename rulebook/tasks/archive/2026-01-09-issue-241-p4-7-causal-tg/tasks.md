## 1. Harness + Evidence
- [ ] 1.1 Add smoke-suite manifest for TG01–TG25
- [ ] 1.2 Run Stata 18 smoke suite and capture report + per-template artifacts

## 2. Template Fixes (TG01–TG25)
- [ ] 2.1 Fix runtime errors and fragile assumptions (PSM/IV/RDD/DID)
- [ ] 2.2 Normalize anchors to `SS_EVENT|k=v` (remove legacy `SS_*:...`)
- [ ] 2.3 Ensure explicit `warn/fail` with `SS_RC` for identification/data-shape violations

## 3. Verification + Delivery
- [ ] 3.1 Re-run smoke suite to 0 fail; run `ruff check .` + `pytest -q`
- [ ] 3.2 Update `openspec/_ops/task_runs/ISSUE-241.md` with commands/output and PR link
