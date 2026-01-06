# Tasks: issue-36-do-template-library

- [ ] Vendor legacy `stata_service/tasks/` into SS as read-only library asset (avoid `tasks/` dir naming).
- [ ] Implement `DoTemplateRepository` port (domain) and `FileSystemDoTemplateRepository` (infra).
- [ ] Implement deterministic placeholder replacement for templates (MVP scope).
- [ ] Implement MVP template run loop that:
  - [ ] Writes generated do-file under `jobs/<job_id>/runs/<run_id>/work/`
  - [ ] Executes via `StataRunner` with cwd isolation
  - [ ] Archives template source/meta/params/stdout/stderr/log + declared outputs into `artifacts/`
- [ ] Add unit tests for repository loading and placeholder replacement/error paths.
- [ ] Run a real Stata 18 execution locally (WSL/Windows) and record commands + key output in `openspec/_ops/task_runs/ISSUE-36.md`.
- [ ] Ensure `ruff check .` and `pytest -q` are green; open PR with `Closes #36`.

