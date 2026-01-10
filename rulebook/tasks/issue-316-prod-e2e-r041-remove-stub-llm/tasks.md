## 1. Implementation
- [ ] 1.1 Remove stub provider branch from `src/infra/llm_client_factory.py`
- [ ] 1.2 Remove runtime `StubLLMClient` implementation from `src/domain/llm_client.py`
- [ ] 1.3 Update config loading to avoid default stub and reject `SS_LLM_PROVIDER=stub`
- [ ] 1.4 Ensure failure uses stable error code `LLM_CONFIG_INVALID`

## 2. Testing
- [ ] 2.1 Replace test runtime stub usage with `tests/**` fake via dependency injection
- [ ] 2.2 Run `ruff check .`
- [ ] 2.3 Run `pytest -q`

## 3. Documentation
- [ ] 3.1 Update run log `openspec/_ops/task_runs/ISSUE-316.md`
