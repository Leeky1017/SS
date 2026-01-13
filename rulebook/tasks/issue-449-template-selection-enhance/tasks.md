# Tasks: Template Selection Enhancement (V2 / Multi-template)

## Issue
- GitHub: #449
- Branch: `task/449-template-selection-enhance`

## Checklist

- [x] Worktree isolation (`.worktrees/issue-449-template-selection-enhance`)
- [x] Add V2 models (`src/domain/do_template_selection_models.py`)
- [x] Update prompts + parsing (`src/domain/do_template_selection_prompting.py`)
- [x] Update selection service + evidence (`src/domain/do_template_selection_service.py`)
- [x] Add tests for multi-template + confidence thresholds
- [x] Run `ruff check .`
- [x] Run `pytest -q`
- [x] Add RUN_LOG (`openspec/_ops/task_runs/ISSUE-449.md`)
- [x] Run `scripts/agent_pr_preflight.sh`
- [x] Create PR (`Closes #449`) + enable auto-merge
