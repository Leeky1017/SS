## 1. Implementation
- [ ] 1.1 Extend `Config` with worker/queue/retry fields
- [ ] 1.2 Implement worker service to claim + execute jobs with retries
- [ ] 1.3 Add worker entrypoint (`python -m src.worker`) wired from `src/config.py`
- [ ] 1.4 Ensure run attempts write meta/artifacts under `runs/<run_id>/`

## 2. Testing
- [ ] 2.1 Add tests: success once / fail then retry success / fail to max
- [ ] 2.2 Run `ruff check .` and `pytest -q`

## 3. Documentation
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-23.md` with commands + key outputs
