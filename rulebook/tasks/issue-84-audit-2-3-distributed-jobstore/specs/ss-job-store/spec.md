# Spec: ss-job-store (delta)

## Purpose

Define the JobStore backend interface and minimum guarantees required to safely run SS in multi-node deployments.

## Requirements

### Requirement: JobStore provides optimistic concurrency control

JobStore save MUST prevent lost updates across processes/nodes, using an explicit version-based compare-and-swap semantic.

#### Scenario: Stale write is rejected
- **GIVEN** a job exists in the store at a newer `version`
- **WHEN** saving a job with an outdated `version`
- **THEN** the operation fails explicitly (no silent overwrite)

### Requirement: Backend selection is explicit and configurable

SS MUST select the JobStore backend via `src/config.py`, with a safe default for development.

#### Scenario: File backend is the default
- **GIVEN** SS is starting up with default configuration
- **WHEN** no backend override is provided
- **THEN** SS uses the file backend
