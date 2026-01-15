## 1. Implementation
- [ ] 1.1 Add OpenAPI export + prune pipeline (backend → OpenAPI JSON)
- [ ] 1.2 Generate frontend TypeScript types from OpenAPI (no manual edits)
- [ ] 1.3 Add CI contract sync check (fail on drift)

## 2. Testing
- [ ] 2.1 Run `scripts/contract_sync.sh check`
- [ ] 2.2 Run `ruff check .` and `pytest -q`

## 3. Documentation
- [ ] 3.1 Update `AGENTS.md` with contract-first rule
- [ ] 3.2 Update run log (`openspec/_ops/task_runs/ISSUE-479.md`)
