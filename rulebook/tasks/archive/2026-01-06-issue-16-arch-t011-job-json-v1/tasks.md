## 1. Implementation
- [ ] 1.1 Update `openspec/specs/ss-job-contract/README.md` with job.json v1 field semantics + schema_version policy
- [ ] 1.2 Expand `src/domain/models.py` for job.json v1 (Job/Draft/ArtifactRef/RunAttempt/LLMPlan) with validations
- [ ] 1.3 Update `src/infra/job_store.py` to validate schema_version and treat Pydantic validation errors as corruption
- [ ] 1.4 Update `src/domain/job_service.py` to persist `schema_version`

## 2. Testing
- [ ] 2.1 Add unit tests for JobStore: valid/missing fields/wrong schema_version/wrong types/corrupt JSON
- [ ] 2.2 Run `pytest -q`

## 3. Documentation
- [ ] 3.1 Run `openspec validate --specs --strict --no-interactive`
- [ ] 3.2 Run `ruff check .`
