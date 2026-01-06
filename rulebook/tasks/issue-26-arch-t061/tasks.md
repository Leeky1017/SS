## 1. Implementation
- [ ] 1.1 Add `src/infra/logging_config.py` (JSON formatter + dictConfig builder)
- [ ] 1.2 Configure `src/main.py` / `src/worker.py` / `src/cli.py` from `Config.log_level`
- [ ] 1.3 Ensure required log keys (`job_id`/`run_id`/`step`) are always present

## 2. Testing
- [ ] 2.1 Add unit tests for logging config/formatter
- [ ] 2.2 Run `ruff check .` and `pytest -q`

## 3. Documentation
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-26.md` with commands + key outputs
