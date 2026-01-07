# Spec: ss-job-store

## Purpose

Define the JobStore backend contract (interface + minimum guarantees) so SS can evolve from a single-node file backend to a production-grade distributed backend without breaking correctness.

## Requirements

### Requirement: JobStore backend selection is explicit

SS MUST select the JobStore backend via `src/config.py`, and MUST NOT read environment variables directly in API/worker/domain code.

#### Scenario: Backend is configured in one place
- **WHEN** reviewing `src/config.py`
- **THEN** JobStore backend selection is configured there (with explicit defaults)

### Requirement: JobStore save prevents lost updates

JobStore MUST provide an explicit optimistic concurrency semantic that prevents silent lost updates across processes/nodes, using the monotonic `version` field in `job.json`.

#### Scenario: Stale write is rejected
- **WHEN** saving a job with a stale `version`
- **THEN** the operation fails explicitly (no silent overwrite)

### Requirement: Distributed backend decision is documented

SS MUST document the chosen distributed JobStore backend (and alternatives) including operational requirements.

#### Scenario: Decision record exists
- **WHEN** reading `openspec/specs/ss-job-store/decision.md`
- **THEN** it compares at least Redis and PostgreSQL and states a concrete decision

### Requirement: Migration path is explicit

SS MUST define an explicit migration path from the file backend to the chosen distributed backend, including rollout steps and a fallback plan.

#### Scenario: Migration doc exists
- **WHEN** reading `openspec/specs/ss-job-store/migration.md`
- **THEN** it defines rollout steps, fallback steps, and data migration considerations

