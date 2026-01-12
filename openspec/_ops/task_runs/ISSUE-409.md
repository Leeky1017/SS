# ISSUE-409
- Issue: #409
- Branch: task/409-layering-shared-app-infra
- PR: https://github.com/Leeky1017/SS/pull/410

## Plan
- Clarify layering terminology (adapters vs shared infra)
- Update OpenSpec constraints to match reality
- Validate specs and open auto-merge PR

## Runs
### 2026-01-12 20:17 init
- Command: `gh issue create -t "[ARCH] Revise layering constraints for shared app infrastructure" ...`
- Key output: `https://github.com/Leeky1017/SS/issues/409`
- Evidence: `openspec/_ops/task_runs/ISSUE-409.md`

### 2026-01-12 20:26 validate openspec specs
- Command: `openspec validate --specs --strict --no-interactive`
- Key output: `Totals: 29 passed, 0 failed (29 items)`
- Evidence: `openspec/specs/ss-constitution/spec.md`, `openspec/specs/ss-ports-and-services/spec.md`

### 2026-01-12 20:26 setup dev env for validation
- Command: `python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"`
- Key output: `Successfully installed ... ruff ... pydantic ...`
- Evidence: `pyproject.toml`

### 2026-01-12 20:26 lint + tests
- Command: `.venv/bin/ruff check . && .venv/bin/pytest -q`
- Key output: `All checks passed!; 194 passed, 5 skipped`
- Evidence: `openspec/_ops/task_runs/ISSUE-409.md`
