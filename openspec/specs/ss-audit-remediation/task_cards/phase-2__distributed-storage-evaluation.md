# Phase 2: Distributed storage evaluation (JobStore backend)

## Background

The audit highlighted that the current single-node file persistence model does not provide strong guarantees under multi-node deployment (e.g., NFS cache/atomicity issues), and requires a clear path to a distributed backend.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏分布式部署的一致性保证”
- `Audit/03_Integrated_Action_Plan.md` → “任务 2.3：分布式存储方案评估”

## Goal

Evaluate and choose a distributed job storage approach and define an explicit migration path from the current file backend to the chosen backend.

## Dependencies & parallelism

- Hard dependencies: `phase-1__data-version-upgrade.md` (schema migration policy must exist first)
- Parallelizable with: LLM timeout/retry, API versioning

## Acceptance checklist

- [x] Define the JobStore backend interface and the minimal guarantees required (consistency, concurrency, failure modes)
- [x] Compare at least two backend options (e.g., Redis, Postgres) with tradeoffs and operational requirements
- [x] Produce a concrete migration plan (rollout steps, fallback plan, data migration considerations)
- [x] Document the decision and how to configure the backend for deployment
- [x] Implementation run log records key commands and the final decision artifact path(s)

## Estimate

- 8-10h

## Completion

- Issue: #84
- PR: https://github.com/Leeky1017/SS/pull/90
- Notes:
  - Decision + tradeoffs: `openspec/specs/ss-job-store/decision.md`
  - Migration plan: `openspec/specs/ss-job-store/migration.md`
  - Contract/spec: `openspec/specs/ss-job-store/spec.md`
- Run log: `openspec/_ops/task_runs/ISSUE-84.md`
