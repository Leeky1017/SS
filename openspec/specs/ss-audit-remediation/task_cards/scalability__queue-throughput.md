# Scalability: Queue throughput + scale path

## Background

The audit flagged that the file-backed queue has an unclear throughput ceiling and lacks a documented scale path for higher worker counts and higher job throughput.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “队列吞吐量设计不清晰”

## Goal

Define a practical queue scalability plan (including throughput targets, failure modes, and a migration path to a scalable queue backend if needed).

## Dependencies & parallelism

- Hard dependencies: `phase-2__distributed-storage-evaluation.md` (queue/backend choices should align with storage decisions)
- Parallelizable with: ops track tasks

## Acceptance checklist

- [x] Define throughput targets and constraints (jobs/min, p95 latency, worker count assumptions)
- [x] Document the queue backend options and recommend a default for production
- [x] Define the rollout/migration plan, including how to test and validate throughput
- [x] Ensure any chosen design preserves single-claimer semantics and bounded retries
- [x] Implementation run log records evidence of measurement and decision

## Estimate

- 8-12h

## Completion

- PR: https://github.com/Leeky1017/SS/pull/99
- Notes:
  - Throughput envelope + migration trigger: `openspec/specs/ss-worker-queue/throughput.md`
  - Production backend decision (Postgres default; Redis/RabbitMQ options): `openspec/specs/ss-worker-queue/decision.md`
  - Rollout/migration checklist: `openspec/specs/ss-worker-queue/migration.md`
  - Repeatable benchmark script: `scripts/bench_queue_throughput.py`
- Run log: `openspec/_ops/task_runs/ISSUE-95.md`
