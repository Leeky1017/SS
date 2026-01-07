# Phase 1: Type annotations completeness + static typing gate

## Background

The audit measured incomplete return type coverage and recommended adding a static typing gate to prevent regressions and improve IDE/tooling support.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “类型注解覆盖度不完全”
- `Audit/03_Integrated_Action_Plan.md` → “任务 1.4：类型注解完整性”

## Goal

Improve type annotation completeness and add a CI-enforced static typing check (e.g., mypy strict) so missing or invalid types fail fast in PRs.

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: data migrations, concurrency protection, graceful shutdown

## Acceptance checklist

- [x] Select and configure a static typing tool in the repo (config checked in)
- [x] CI runs the type check and fails on typing errors
- [x] Missing return type annotations are filled in (or functions are refactored to be typable)
- [x] A short developer workflow note exists (how to run the type check locally)
- [x] Implementation run log records `ruff check .`, `pytest -q`, and the typing command

## Estimate

- 3-4h

## Completion

- PR: https://github.com/Leeky1017/SS/pull/78
- Notes:
  - `pyproject.toml` adds mypy strict config and dev dependency
  - CI (`ci` + `merge-serial`) runs `mypy` as a required gate
  - Missing/invalid type annotations fixed across `src/` and local workflow documented in `README.md`
- Run log: `openspec/_ops/task_runs/ISSUE-75.md`
