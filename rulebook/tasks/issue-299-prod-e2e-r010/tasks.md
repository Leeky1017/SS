## 1. Implementation
- [x] 1.1 Inject `FileSystemDoTemplateCatalog` + `FileSystemDoTemplateRepository` via `src/api/deps.py`.
- [x] 1.2 Update `PlanService` to select a real `template_id` and emit `template_params`.
- [x] 1.3 Update `DoFileGenerator` to render templates via injected repository.
- [x] 1.4 Update worker assembly to inject do-template repository into `WorkerService`.

## 2. Testing
- [x] 2.1 Add unit tests for filesystem catalog/repository adapters.
- [x] 2.2 Run `ruff check .` and `pytest -q`.

## 3. Documentation
- [x] 3.1 Update task card and run log: `openspec/specs/ss-production-e2e-audit-remediation/task_cards/round-01-prod-a__PROD-E2E-R010.md`, `openspec/_ops/task_runs/ISSUE-299.md`.

