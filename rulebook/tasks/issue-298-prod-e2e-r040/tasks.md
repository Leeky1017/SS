# Tasks: issue-298-prod-e2e-r040

- [ ] Define production mode switch in `src/config.py` (single source of truth).
- [ ] Update `src/domain/health_service.py` readiness to enforce production gate:
  - [ ] LLM provider must be non-stub and have required config.
  - [ ] Stata runner must be real (requires `SS_STATA_CMD`).
  - [ ] Upload object store must be non-fake and have required config.
- [ ] Add tests covering production gate ok/failed branches.
- [ ] Record evidence in `openspec/_ops/task_runs/ISSUE-298.md` (commands + key output).
- [ ] Ensure `ruff check .` and `pytest -q` are green.

