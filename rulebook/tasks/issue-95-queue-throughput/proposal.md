# Proposal: issue-95-queue-throughput

## Why
The audit flagged that the current file-backed queue has an unclear throughput ceiling and no documented scale path. This blocks planning for higher worker counts / higher job throughput and risks correctness regressions when migrating to a distributed queue backend.

## What Changes
- Add an explicit throughput/scale plan for the current `FileWorkerQueue` (constraints, targets, and measurement method).
- Document queue backend options (Postgres/Redis/RabbitMQ) and recommend a production default aligned with the JobStore decision.
- Define a concrete rollout/migration plan and validation checklist.

## Impact
- Affected specs:
  - `openspec/specs/ss-worker-queue/spec.md`
  - `openspec/specs/ss-audit-remediation/task_cards/scalability__queue-throughput.md`
- Affected code:
  - `scripts/bench_queue_throughput.py` (new benchmark script)
- Breaking change: NO
- User benefit: Clear throughput envelope for the current queue and a low-risk path to scale beyond single-node file queue.
