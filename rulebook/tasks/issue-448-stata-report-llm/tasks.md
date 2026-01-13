# Tasks: Stata Result Interpretation Report

## Issue
- GitHub: #448
- Branch: `task/448-stata-report-llm`

## Checklist

- [x] Worktree isolation (`.worktrees/issue-448-stata-report-llm`)
- [x] Add domain models (`src/domain/stata_report_models.py`)
- [x] Add rule-based parser (`src/domain/stata_result_parser.py`)
- [x] Add prompt+parser (`src/domain/stata_report_llm.py`)
- [x] Add service orchestration (`src/domain/stata_report_service.py`)
- [x] Add `ArtifactKind.STATA_REPORT_INTERPRETATION` (`src/domain/models.py`)
- [x] Add unit/integration tests (4 new test files)
- [x] Run `ruff check .`
- [x] Run `pytest -q`
- [x] Add RUN_LOG (`openspec/_ops/task_runs/ISSUE-448.md`)
- [x] Run `scripts/agent_pr_preflight.sh`
- [x] Create PR (`Closes #448`) + enable auto-merge
