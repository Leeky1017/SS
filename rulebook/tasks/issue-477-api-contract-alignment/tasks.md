## 1. Implementation
- [x] 1.1 Update `FreezePlanRequest` to include optional `answers`
- [x] 1.2 Update `PlanStepResponse.params` to use `JsonValue`
- [x] 1.3 Add `selected_template_id` to `GetJobResponse`
- [x] 1.4 Tighten `DraftPreview*Response.status` to `Literal[...]`
- [x] 1.5 Add `draft/preview` passthrough type guards via `list_of_dicts()`

## 2. Testing
- [x] 2.1 `ruff check src/ frontend/`
- [x] 2.2 (frontend) `npx tsc --noEmit`
- [x] 2.3 `mypy src/api/`
- [x] 2.4 `pytest tests/ -v --tb=short`
- [x] 2.5 `openspec validate --specs --strict --no-interactive`

## 3. Documentation
- [x] 3.1 Add run log `openspec/_ops/task_runs/ISSUE-477.md`
