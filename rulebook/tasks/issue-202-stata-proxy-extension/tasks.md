## 1. Spec (this issue)
- [x] 1.1 Write OpenSpec: `openspec/backend-stata-proxy-extension/spec.md`
- [x] 1.2 Specify schema deltas (`src/domain/models.py`, `src/api/schemas.py`)
- [x] 1.3 Specify service deltas (DraftService/PlanService/JobService)
- [x] 1.4 Specify full API request/response JSON + dataflow mermaid
- [x] 1.5 Specify acceptance tests (variable corrections + freeze validation + preview shape)

## 2. Implementation (follow-up issues; not in this PR)
- [ ] 2.1 Add `variable_corrections` to confirmation/request models (domain + API schemas)
- [ ] 2.2 Implement token-boundary variable correction applier and apply to Do-file generation path
- [ ] 2.3 Extend DraftService + API schema to return structured preview fields
- [ ] 2.4 Add contract freeze column cross-validation before queueing execution (PlanService)
- [ ] 2.5 Ensure plan_id includes confirmation payload (idempotent + conflict-safe)
- [ ] 2.6 Add tests:
  - unit: token-boundary replacement
  - integration: confirm with variable_corrections rewrites do-file tokens
  - integration: freeze rejects unknown columns
  - integration: draft preview response includes structured fields

## 3. Delivery (this PR)
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-202.md` with key commands + outputs
- [ ] 3.2 Run `scripts/agent_pr_preflight.sh`
- [ ] 3.3 Open PR with `Closes #202` and enable auto-merge

