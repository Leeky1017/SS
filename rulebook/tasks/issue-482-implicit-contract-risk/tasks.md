## 1. Implementation
- [ ] 1.1 Add typed `stage1_questions`/`open_unknowns` to domain Draft
- [ ] 1.2 Remove implicit dict-merge usage; adapt draft service/contract helpers
- [ ] 1.3 Mark unused bundle/upload-sessions endpoints as internal in OpenAPI

## 2. Testing
- [ ] 2.1 Update/add unit tests for Draft enrichment + patch unknown counts
- [ ] 2.2 Run `ruff check .` and `pytest -q`
- [ ] 2.3 Run `scripts/contract_sync.sh generate` + `scripts/contract_sync.sh check`

## 3. Documentation
- [ ] 3.1 Add spec delta + update run log
