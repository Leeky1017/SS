## 1. Implementation
- [ ] 1.1 Add `tests/chaos/` + shared fault-injection fixtures
- [ ] 1.2 Add disk full recovery tests (job.json + artifact writes)
- [ ] 1.3 Add permission loss tests (non-writable workspace)
- [ ] 1.4 Add OOM handling test (deterministic MemoryError simulation)
- [ ] 1.5 Add LLM long-unavailable failover test (timeout → fallback)

## 2. Testing
- [ ] 2.1 Run `ruff check .`
- [ ] 2.2 Run `pytest -q`
- [ ] 2.3 Record key output in `openspec/_ops/task_runs/ISSUE-107.md`

## 3. Documentation
- [ ] 3.1 Update task card completion (post-merge)
- [ ] 3.2 Backfill PR link in run log (post-PR creation)
