# ss-audit-remediation

This spec pack converts the existing audit reports under `Audit/` into an executable remediation backlog (requirements + task cards).

## Sources (authoritative inputs)

- `Audit/INDEX.md`
- `Audit/01_Executive_Summary.md`
- `Audit/02_Deep_Dive_Analysis.md`
- `Audit/03_Integrated_Action_Plan.md`

## Priorities (execution framing)

- Phase 1 (P0): production safety foundations (data migration, concurrency, graceful shutdown, typing gate)
- Phase 2 (P1): reliability + compatibility (LLM timeout/retry, API versioning, distributed storage evaluation)
- Scalability: throughput and growth-path items (queue, sharding, multi-tenant)
- Ops: production operability (metrics, health checks, tracing, audit logs)

## Task cards

| Category | Task card | Estimate | Hard dependencies |
|---|---|---:|---|
| Phase 1 | `task_cards/phase-1__data-version-upgrade.md` | 6-8h | - |
| Phase 1 | `task_cards/phase-1__jobstore-concurrency-race-protection.md` | 8-10h | `task_cards/phase-1__data-version-upgrade.md` |
| Phase 1 | `task_cards/phase-1__graceful-shutdown.md` | 4-6h | - |
| Phase 1 | `task_cards/phase-1__typing-annotations.md` | 3-4h | - |
| Phase 2 | `task_cards/phase-2__llm-timeout-retry.md` | 4-6h | - |
| Phase 2 | `task_cards/phase-2__api-versioning.md` | 3-5h | - |
| Phase 2 | `task_cards/phase-2__distributed-storage-evaluation.md` | 8-10h | `task_cards/phase-1__data-version-upgrade.md` |
| Scalability | `task_cards/scalability__queue-throughput.md` | 8-12h | `task_cards/phase-2__distributed-storage-evaluation.md` |
| Scalability | `task_cards/scalability__job-store-sharding.md` | 4-6h | `task_cards/phase-1__data-version-upgrade.md` |
| Scalability | `task_cards/scalability__multi-tenant-support.md` | 12-16h | `task_cards/scalability__job-store-sharding.md` |
| Ops | `task_cards/ops__metrics-export.md` | 4-6h | - |
| Ops | `task_cards/ops__health-check.md` | 2-4h | - |
| Ops | `task_cards/ops__distributed-tracing.md` | 4-6h | - |
| Ops | `task_cards/ops__audit-logging.md` | 4-6h | - |

## How to execute

- Use the SS delivery workflow gates: `openspec/specs/ss-delivery-workflow/spec.md`.
- For each task card, create a GitHub Issue and deliver it via a PR with a run log entry under `openspec/_ops/task_runs/`.
