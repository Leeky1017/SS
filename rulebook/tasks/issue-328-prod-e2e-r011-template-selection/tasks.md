# Tasks: issue-328-prod-e2e-r011-template-selection

- [ ] Wire `DoTemplateSelectionService` into `GET /v1/jobs/{job_id}/draft/preview`
- [ ] Persist selection evidence artifacts (stage1/candidates/stage2)
- [ ] Persist `selected_template_id` onto the job record
- [ ] Remove `stub_descriptive_v1` hardcode from the `/v1` plan chain
- [ ] Add/adjust tests for selection + persistence
- [ ] Run `ruff check .` and `pytest -q`; record in `openspec/_ops/task_runs/ISSUE-328.md`
- [ ] Open PR with `Closes #328` and enable auto-merge
