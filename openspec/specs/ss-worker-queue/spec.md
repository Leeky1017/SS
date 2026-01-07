# Spec: ss-worker-queue

## Purpose

Define SS worker and queue contracts so background execution is isolated, single-claimer, and retryable.

## Requirements

### Requirement: Worker runs outside the API process

The worker MUST run independently from the API process and MUST be able to execute queued jobs without relying on in-process execution.

#### Scenario: Worker is a separate entrypoint
- **WHEN** running SS in development
- **THEN** worker can be started as a standalone process

### Requirement: Queue claim prevents double execution

Queue claiming MUST be atomic and MUST ensure the same job is not executed concurrently by multiple workers.

#### Scenario: Two workers cannot claim the same job
- **WHEN** two workers attempt to claim the same queued job
- **THEN** at most one claim succeeds

### Requirement: Claim leases expire and are reclaimable

A claim MUST have a bounded lease duration, and an expired claim MUST be reclaimable so jobs cannot be permanently lost when a worker crashes or hangs.

#### Scenario: Expired claim can be reclaimed
- **WHEN** a worker claims a job and does not ack/release before the lease expires
- **THEN** another worker can reclaim and claim the same job

### Requirement: Each run attempt is isolated and archived

Each execution attempt MUST create a new `run_id` directory and MUST persist attempt metadata and artifacts for audit and retry.

#### Scenario: Run attempt produces evidence
- **WHEN** a job is executed (success or failure)
- **THEN** run metadata and logs exist under the run attempt directory

### Requirement: Retry policy is configurable and bounded

Retry/backoff and maximum attempts MUST be configurable via `src/config.py`, and reaching the max MUST transition the job to `failed` with evidence artifacts preserved.

#### Scenario: Retries stop after max_attempts
- **WHEN** repeated failures reach the configured attempt limit
- **THEN** the job ends in `failed` with preserved evidence

### Requirement: Queue throughput constraints are explicit

SS MUST document queue throughput targets and the operating constraints for the current file-backed queue (including worker-count assumptions and claim latency expectations).

#### Scenario: Throughput envelope is documented
- **WHEN** reading `openspec/specs/ss-worker-queue/throughput.md`
- **THEN** it defines measurable targets and a clear migration trigger

### Requirement: Production queue backend decision is documented

SS MUST document the recommended production queue backend (and alternatives) aligned with JobStore deployment decisions.

#### Scenario: Decision record exists
- **WHEN** reading `openspec/specs/ss-worker-queue/decision.md`
- **THEN** it compares at least PostgreSQL and Redis (and states a concrete decision)

### Requirement: Queue migration path is explicit

SS MUST define an explicit migration plan from the file queue to a production queue backend, including rollout steps and a fallback plan.

#### Scenario: Migration doc exists
- **WHEN** reading `openspec/specs/ss-worker-queue/migration.md`
- **THEN** it defines rollout steps, fallback steps, and validation guidance
