## 1. Implementation
- [ ] 1.1 Add `tests/e2e/` scaffolding + fixtures
- [ ] 1.2 Layer 1: API entry endpoint coverage
- [ ] 1.3 Layer 2: input processing edge cases
- [ ] 1.4 Layer 3: LLM resilience + retry behavior (fake LLM)
- [ ] 1.5 Layer 4: confirm/correction idempotency + locking
- [ ] 1.6 Layer 5: execution success/fail/timeout + retry (fake runner; real Stata optional)
- [ ] 1.7 Layer 6: state machine + concurrency safety

## 2. Testing
- [ ] 2.1 Run `ruff check .`
- [ ] 2.2 Run `pytest -q` (focus `tests/e2e/`, then full suite)

## 3. Documentation
- [ ] 3.1 Add coverage report + findings list under `tests/e2e/`
- [ ] 3.2 Update `openspec/_ops/task_runs/ISSUE-483.md` with runs + outputs
