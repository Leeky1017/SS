## 1. Implementation
- [x] 1.1 Add TH smoke-suite manifest (fixtures + params).
- [x] 1.2 Fix Stata runtime failures in TH templates (Stata 18 harness).
- [x] 1.3 Normalize legacy anchors to `SS_EVENT|k=v` within TH scope.
- [x] 1.4 Add defensive `tsset` prechecks + fallback `ss_time_index` for non-unique timevars.

## 2. Verification
- [x] 2.1 Run smoke suite and confirm 0 failed (missing SSC deps reported as `missing_deps`).
- [x] 2.2 Run `ruff` + `pytest` + `openspec validate` and record evidence in run log.

## 3. Delivery
- [x] 3.1 Update task card metadata with Issue number.
- [x] 3.2 Maintain `openspec/_ops/task_runs/ISSUE-255.md` with commands + key outputs.
- [ ] 3.3 Open PR with `Closes #255` and enable auto-merge.
