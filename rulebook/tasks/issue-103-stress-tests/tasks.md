## 1. Implementation
- [ ] Add `tests/stress/` fixtures and metrics helpers (skip-by-default)
- [ ] Implement scenario 1 load test (100 users + 50 runs + 200 queries)
- [ ] Implement scenario 2 long-run stability test (24h configurable; bounded by env)
- [ ] Implement scenario 4 boundary tests (1GB CSV, 100k input, 500 columns)
- [ ] Add pytest-benchmark baseline latency benchmark for a hot endpoint

## 2. Testing
- [ ] Run `ruff check .`
- [ ] Run `pytest -q`
- [ ] (Dedicated env) Run `SS_RUN_STRESS_TESTS=1 pytest -q tests/stress -s`

## 3. Documentation
- [ ] Add run log: `openspec/_ops/task_runs/ISSUE-103.md`
- [ ] Update task card checklist: `openspec/specs/ss-testing-strategy/task_cards/stress.md`
- [ ] Add spec delta under `rulebook/tasks/issue-103-stress-tests/specs/`
