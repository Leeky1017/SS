## 1. Implementation
- [ ] 1.1 Add TM01–TM15 smoke-suite manifest + fixtures
- [ ] 1.2 Fix TM01–TM15 runtime errors under Stata 18 harness
- [ ] 1.3 Normalize anchors to pipe-delimited `SS_*|k=v` and unify style
- [ ] 1.4 Treat non-built-in commands as explicit deps (emit `SS_DEP_*` anchors)

## 2. Verification
- [ ] 2.1 Run TM smoke suite and reach 0 `failed`
- [ ] 2.2 Run `ruff check .` and `pytest -q`

## 3. Delivery
- [ ] 3.1 Update run log (`openspec/_ops/task_runs/ISSUE-273.md`) with evidence
- [ ] 3.2 Run `scripts/agent_pr_preflight.sh`
- [ ] 3.3 Open PR, enable auto-merge, and verify merge
