## 1. Implementation
- [ ] 1.1 Extend plan freeze plan step params with `template_id`, `params_contract`, `dependencies`, `outputs_contract`
- [ ] 1.2 Persist contract into `artifacts/plan.json` and return in API response
- [ ] 1.3 Emit structured error when template meta is missing/corrupt (with context)

## 2. Testing
- [ ] 2.1 Unit tests: missing `meta.json` -> structured error code + context
- [ ] 2.2 Unit tests: invalid JSON meta -> structured error code + context

## 3. Documentation
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-333.md` with key commands + outputs
- [ ] 3.2 Update task card `round-01-prod-a__PROD-E2E-R012.md` Issue/Completion
