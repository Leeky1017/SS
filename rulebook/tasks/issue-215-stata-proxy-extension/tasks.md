## 1. Implementation
- [ ] 1.1 Update domain models: `JobConfirmation`, `Draft`, add supporting models
- [ ] 1.2 Update API schemas and endpoints: confirm payload + draft preview response
- [ ] 1.3 Implement variable corrections (clean + token-boundary apply) and apply in confirm→freeze
- [ ] 1.4 Implement freeze-time column validation against primary dataset columns

## 2. Testing
- [ ] 2.1 Unit: token-boundary replacement + idempotency
- [ ] 2.2 Integration: confirm corrections affect do-file tokens; freeze rejects missing corrected columns; plan_id changes on confirmation payload change

## 3. Documentation
- [ ] 3.1 Keep canonical requirements in `openspec/specs/backend-stata-proxy-extension/spec.md`
- [ ] 3.2 Update `openspec/_ops/task_runs/ISSUE-215.md` with key command evidence
