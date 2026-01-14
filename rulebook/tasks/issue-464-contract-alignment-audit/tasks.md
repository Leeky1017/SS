## 1. Implementation
- [ ] 1.1 Read authoritative OpenSpec contracts for `/v1` endpoints in scope
- [ ] 1.2 Audit backend schemas/contracts vs frontend TS types and consumers (Step3 + Desktop Pro)
- [ ] 1.3 Write audit report: `openspec/_ops/audits/frontend-backend-contract-alignment.md`
- [ ] 1.4 Fix backend response payloads to match `src/api/schemas.py`
- [ ] 1.5 Update frontend TS types to exactly match backend schemas

## 2. Testing
- [ ] 2.1 Add/adjust regression tests for critical contract fields (incl `stage1_questions[].options`)
- [ ] 2.2 Run `ruff check .` and `pytest -q`
- [ ] 2.3 Manual smoke: run backend locally; call `GET /v1/jobs/{job_id}/draft/preview` and confirm correct response shape

## 3. Documentation
- [ ] 3.1 Keep a complete mismatch inventory in `openspec/_ops/audits/frontend-backend-contract-alignment.md`
- [ ] 3.2 Update `openspec/_ops/task_runs/ISSUE-464.md` with key commands/outputs and PR link
