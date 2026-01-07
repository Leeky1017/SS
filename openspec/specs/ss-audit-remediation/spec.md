# Spec: ss-audit-remediation

## Purpose

Convert the existing SS audit reports under `Audit/` into a prioritized set of remediation requirements and task cards that can be executed via the SS delivery workflow.

## Requirements

### Requirement: Remediation backlog is captured in OpenSpec

The audit findings MUST be translated into OpenSpec requirements and MUST be represented as task cards under `openspec/specs/ss-audit-remediation/task_cards/`.

#### Scenario: Remediation spec pack exists
- **WHEN** browsing `openspec/specs/ss-audit-remediation/`
- **THEN** `spec.md`, `README.md`, and `task_cards/` exist

### Requirement: Data versions are upgradable (job.json + plan)

SS MUST support forward-compatible upgrades for persisted data (at least `job.json`) and MUST provide an explicit migration path for older supported versions.

#### Scenario: Older job.json can be loaded and migrated
- **WHEN** a persisted `job.json` with an older supported `schema_version` is loaded
- **THEN** SS migrates it to the current schema and records a migration event

Evidence: `openspec/specs/ss-audit-remediation/task_cards/phase-1__data-version-upgrade.md`

### Requirement: Job persistence is concurrency-safe under read-modify-write

SS MUST prevent lost updates when multiple processes modify the same job concurrently (API + worker, or multiple workers), using optimistic locking or an equivalent mechanism.

#### Scenario: Concurrent updates are detected
- **WHEN** two writers attempt to persist conflicting updates to the same job
- **THEN** at least one write is rejected with a structured conflict error and no update is silently lost

Evidence: `openspec/specs/ss-audit-remediation/task_cards/phase-1__jobstore-concurrency-race-protection.md`

### Requirement: Processes shut down gracefully without corrupting job state

SS MUST implement graceful shutdown for API and worker processes to avoid leaving jobs in an inconsistent state (e.g., stuck in `running`) and to release resources cleanly.

#### Scenario: SIGTERM triggers a bounded graceful shutdown
- **WHEN** the process receives a shutdown signal
- **THEN** it stops taking new work, completes or times out in-flight work, and exits after emitting shutdown logs

Evidence: `openspec/specs/ss-audit-remediation/task_cards/phase-1__graceful-shutdown.md`

### Requirement: Type annotations and static typing are enforced

SS MUST improve type annotation completeness and MUST gate the repository with a static type check configured in CI.

#### Scenario: Static typing gate is part of CI
- **WHEN** CI runs on a PR
- **THEN** a static type check runs and fails on missing or invalid types

Evidence: `openspec/specs/ss-audit-remediation/task_cards/phase-1__typing-annotations.md`

### Requirement: LLM calls have explicit timeout and retry behavior

SS MUST define an explicit timeout, retry count, and backoff policy for LLM calls and MUST emit structured logs for timeouts and final failures.

#### Scenario: LLM call times out and retries
- **WHEN** an LLM call exceeds the configured timeout
- **THEN** SS logs a timeout event, retries according to policy, and fails deterministically after the final attempt

Evidence: `openspec/specs/ss-audit-remediation/task_cards/phase-2__llm-timeout-retry.md`

### Requirement: HTTP API is versioned and has a deprecation policy

SS MUST support API versioning (at least `/v1`) and MUST define a deprecation mechanism so breaking changes can be introduced without silently breaking clients.

#### Scenario: Versioned routes can coexist
- **WHEN** a new API version is introduced
- **THEN** the previous version remains available during a defined deprecation window

Evidence: `openspec/specs/ss-audit-remediation/task_cards/phase-2__api-versioning.md`

### Requirement: Distributed storage is evaluated with a clear migration path

SS MUST evaluate distributed job storage options and MUST define an explicit migration path from the current single-node file backend to a production-ready backend.

#### Scenario: Storage backend decision is explicit
- **WHEN** preparing for multi-node deployment
- **THEN** there is a documented backend choice, tradeoffs, and a migration plan

Evidence: `openspec/specs/ss-audit-remediation/task_cards/phase-2__distributed-storage-evaluation.md`

### Requirement: Queue throughput constraints and scale path are defined

SS MUST define queue throughput constraints and MUST define the scale path for moving beyond single-node file-backed queue performance.

#### Scenario: Queue scalability plan is actionable
- **WHEN** planning a higher-throughput deployment
- **THEN** the chosen queue approach and rollout steps are documented

Evidence: `openspec/specs/ss-audit-remediation/task_cards/scalability__queue-throughput.md`

### Requirement: Job store sharding strategy exists for large job volumes

SS MUST define a sharding strategy for job storage to avoid filesystem limits and operational degradation at high job counts.

#### Scenario: Job path scheme supports sharding
- **WHEN** job count grows beyond a single-directory filesystem limit
- **THEN** the storage layout supports sharding without breaking job lookup

Evidence: `openspec/specs/ss-audit-remediation/task_cards/scalability__job-store-sharding.md`

### Requirement: Multi-tenant support can be introduced without breaking isolation

SS MUST define a multi-tenant strategy including tenant isolation boundaries and required request context so multiple tenants can share an SS deployment safely.

#### Scenario: Tenant boundaries are enforced in persistence
- **WHEN** two tenants have jobs with the same `job_id`
- **THEN** their persisted data is isolated and cannot collide

Evidence: `openspec/specs/ss-audit-remediation/task_cards/scalability__multi-tenant-support.md`

### Requirement: Metrics are exportable for monitoring and alerting

SS MUST export runtime metrics suitable for production monitoring (job throughput, latency, error rates, worker activity).

#### Scenario: Metrics endpoint exists
- **WHEN** the service is running
- **THEN** operators can scrape metrics from an HTTP endpoint

Evidence: `openspec/specs/ss-audit-remediation/task_cards/ops__metrics-export.md`

### Requirement: Health checks support orchestration and safe rollouts

SS MUST provide liveness and readiness health checks that allow orchestration systems to make safe decisions (start, stop, and rollout).

#### Scenario: Readiness reflects dependency availability
- **WHEN** a required dependency is unavailable
- **THEN** readiness reports failure while liveness stays healthy

Evidence: `openspec/specs/ss-audit-remediation/task_cards/ops__health-check.md`

### Requirement: Distributed tracing supports end-to-end diagnosis

SS MUST support distributed tracing so a single job can be traced across API and worker execution.

#### Scenario: A job run has a trace identifier
- **WHEN** a job is created and executed
- **THEN** logs and traces share a common trace identifier for correlation

Evidence: `openspec/specs/ss-audit-remediation/task_cards/ops__distributed-tracing.md`

### Requirement: Audit logging captures user and system actions

SS MUST emit audit events for sensitive or state-changing operations so operators can answer who did what, when, and why.

#### Scenario: State changes produce audit events
- **WHEN** a user action causes a job state change
- **THEN** an audit event is recorded with the action, resource, timestamp, and resulting state

Evidence: `openspec/specs/ss-audit-remediation/task_cards/ops__audit-logging.md`
