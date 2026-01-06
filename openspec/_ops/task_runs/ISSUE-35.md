# ISSUE-35

- Issue: #35
- Branch: task/35-openspec-workflow-do-library
- PR: https://github.com/Leeky1017/SS/pull/37

## Plan
- Update SS OpenSpec collaboration workflow docs (canonical).
- Decide legacy `stata_service/tasks` (do library) reuse policy and boundaries.

## Runs

### 2026-01-06 15:55 OpenSpec strict validation
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 4 passed, 0 failed (4 items)`

### 2026-01-06 15:55 Ruff
- Command:
  - `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`

### 2026-01-06 15:55 Pytest
- Command:
  - `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output:
  - `3 passed`

### 2026-01-06 15:55 Planning evidence
- Links:
  - Issue: https://github.com/Leeky1017/SS/issues/36
- Files:
  - `openspec/specs/ss-constitution/10-delivery-workflow.md`
  - `openspec/specs/ss-constitution/11-do-template-library.md`
