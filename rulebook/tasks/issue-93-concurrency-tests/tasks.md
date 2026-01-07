## 1. Implementation
- [x] 1.1 Add `tests/concurrent/` and shared fixtures
- [x] 1.2 Scenario 1: concurrent job modifications test
- [x] 1.3 Scenario 2: worker updates while user queries test
- [x] 1.4 Scenario 3: multi-worker queue no-duplicate/no-missing test
- [x] 1.5 Scenario 4: atomic save/load under contention test

## 2. Testing
- [x] 2.1 `ruff check .`
- [x] 2.2 `pytest tests/concurrent/ -v --count=10`

## 3. Documentation
- [x] 3.1 Update run log: `openspec/_ops/task_runs/ISSUE-93.md`
