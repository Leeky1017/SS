# Phase 1: Concurrency race protection (JobStore read-modify-write)

## Background

The audit identified a lost-update risk: the file backend is atomically written, but the higher-level read → modify → save flow is not atomic, so concurrent writers can silently overwrite each other.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏并发控制与竞态条件防护”
- `Audit/03_Integrated_Action_Plan.md` → “任务 1.2：并发竞态防护”

## Goal

Prevent lost updates when multiple processes modify the same job concurrently, using an explicit concurrency control strategy (preferably optimistic locking based on a persisted version field).

## Dependencies & parallelism

- Hard dependencies: `phase-1__data-version-upgrade.md` (introduces migration policy needed for adding a version field)
- Parallelizable with: graceful shutdown, typing gate

## Acceptance checklist

- [ ] Persist a monotonic job `version` (or equivalent) suitable for optimistic concurrency control
- [ ] JobStore save detects version conflicts and fails with a structured error (no silent overwrites)
- [ ] State transitions continue to be enforced by the domain state machine (logical correctness + physical concurrency)
- [ ] Tests cover a conflict scenario (two writers based on the same initial version)
- [ ] Implementation run log records `ruff check .`, `pytest -q`, and `openspec validate --specs --strict --no-interactive`

## Estimate

- 8-10h

