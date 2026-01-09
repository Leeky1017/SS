## 1. Implementation
- [ ] 1.1 Create a smoke-suite manifest for TF scope (fixtures + params + deps).
- [ ] 1.2 Normalize anchors within scope (remove colon formats; use `SS_EVENT|k=v`).
- [ ] 1.3 Fix runtime issues found by Stata 18 harness (including SSC dep checks and panel preconditions).
- [ ] 1.4 Run Stata 18 harness until report shows 0 `failed` for all in-scope templates.
- [ ] 1.5 Update task card metadata and record evidence in `openspec/_ops/task_runs/ISSUE-240.md`.

## 2. Testing
- [ ] 2.1 `ruff check .`
- [ ] 2.2 `pytest -q`
- [ ] 2.3 `openspec validate --specs --strict --no-interactive`

## 3. Documentation
- [ ] 3.1 Add/Update run log: `openspec/_ops/task_runs/ISSUE-240.md`

