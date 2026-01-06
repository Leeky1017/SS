# ISSUE-38

- Issue: #38
- Branch: task/38-split-contract-specs-task-cards
- PR: (fill)

## Plan
- Split SS contract docs into smaller OpenSpec specs.
- Introduce `task_cards/` as Issue blueprints (not task tracker).

## Runs

### 2026-01-06 16:25 OpenSpec strict validation
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 14 passed, 0 failed (14 items)`

### 2026-01-06 16:25 Ruff
- Command:
  - `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`

### 2026-01-06 16:25 Pytest
- Command:
  - `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output:
  - `3 passed`

### 2026-01-06 16:25 Files
- New specs:
  - `openspec/specs/ss-job-contract/`
  - `openspec/specs/ss-state-machine/`
  - `openspec/specs/ss-api-surface/`
  - `openspec/specs/ss-llm-brain/`
  - `openspec/specs/ss-worker-queue/`
  - `openspec/specs/ss-stata-runner/`
  - `openspec/specs/ss-do-template-library/`
  - `openspec/specs/ss-delivery-workflow/`
  - `openspec/specs/ss-roadmap/`
- Task cards:
  - `openspec/specs/ss-roadmap/task_cards/`
