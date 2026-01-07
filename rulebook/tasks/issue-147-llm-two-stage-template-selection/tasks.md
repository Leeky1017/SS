# Tasks: issue-147-llm-two-stage-template-selection

- [x] Specify Stage-1/Stage-2 prompts + JSON schemas in OpenSpec
- [x] Implement Stage-1 family selection (canonical IDs, reasons, confidence)
- [x] Implement Stage-2 template selection with hard membership enforcement + bounded retry
- [x] Implement deterministic token budgeting + topK trimming (test-covered)
- [x] Write selection artifacts into run evidence (`do_template.*` kinds)
- [x] Record `ruff check .` + `pytest -q` in `openspec/_ops/task_runs/ISSUE-147.md`
