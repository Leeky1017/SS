# Phase 1: Data version upgrade (job.json migrations)

## Background

The audit found that persisted jobs are rejected when `schema_version` differs from the current constant, which makes any future `job.json` evolution a breaking change with no migration path.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏数据迁移/版本升级策略”
- `Audit/03_Integrated_Action_Plan.md` → “任务 1.1：数据版本升级策略”

## Goal

Introduce an explicit, forward-compatible data migration policy for persisted job data:
- read supports a bounded set of older versions and migrates to the current schema
- write always writes the current schema
- migrations are observable (structured logs) and test-covered

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: graceful shutdown, typing gate

## Acceptance checklist

- [ ] Define a schema versioning policy (supported read versions, current write version) in the job contract docs
- [ ] JobStore load supports older versions via explicit migration steps (no “reject everything” behavior for supported versions)
- [ ] Migration emits a structured log event including `job_id`, `from_version`, and `to_version`
- [ ] Tests cover at least one real migration path and at least one unsupported-version rejection path
- [ ] Implementation run log records `ruff check .`, `pytest -q`, and `openspec validate --specs --strict --no-interactive`

## Estimate

- 6-8h

