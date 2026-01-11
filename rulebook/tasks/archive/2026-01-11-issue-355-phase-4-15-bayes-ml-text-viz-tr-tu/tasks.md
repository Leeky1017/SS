## 1. Implementation
- [ ] 1.1 Add TR–TU smoke-suite manifest (fixtures + params + deps)
- [ ] 1.2 Run smoke-suite; triage failures and missing deps
- [ ] 1.3 Fix template runtime errors (Stata 18)
- [ ] 1.4 Normalize anchors to `SS_EVENT|k=v` (+ `SS_RC` warn/fail)
- [ ] 1.5 Normalize template style across scope
- [ ] 1.6 Align meta + index if required by validation gates

## 2. Testing
- [ ] 2.1 Run `pytest -q` (CI-safe static gates)
- [ ] 2.2 Run `ruff check .`
- [ ] 2.3 Rerun smoke-suite report; confirm 0 `fail`

## 3. Documentation
- [ ] 3.1 Update the task card `phase-4.15__bayes-ml-text-viz-TR-TU.md` with `Issue: #355` and completion links
- [ ] 3.2 Update run log `openspec/_ops/task_runs/ISSUE-355.md` with commands + evidence paths
