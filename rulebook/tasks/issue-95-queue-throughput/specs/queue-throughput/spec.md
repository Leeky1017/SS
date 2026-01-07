# Spec: issue-95-queue-throughput

## Purpose

Define explicit throughput constraints for the current file-backed worker queue and document an actionable scale path to higher-throughput queue backends while preserving correctness (single-claimer semantics + bounded retries).

## Scope

- In scope:
  - Throughput targets and operational constraints (jobs/min, p95 claim latency, worker assumptions)
  - Benchmark method for the current file queue (evidence recorded in run log)
  - Queue backend options (Postgres/Redis/RabbitMQ) and a recommended default aligned with JobStore decisions
  - A rollout/migration plan with validation steps
- Out of scope:
  - Implementing a new distributed queue backend (captured as follow-up tasks)

## Acceptance

- Throughput targets and constraints are written as measurable requirements.
- A decision record exists for the recommended production queue backend.
- A migration/rollout plan exists, including how to benchmark and validate.
- Single-claimer semantics and bounded retries are preserved by design.

