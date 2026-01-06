# Spec delta: job.json v1 schema + models (Issue #16)

## Purpose

Lock down `job.json` v1 as a schema-validated contract (Pydantic-backed) so downstream services can evolve safely.

## Requirements

### Requirement: job.json includes schema_version and is validated on load

`JobStore.load()` MUST reject records without `schema_version` and MUST reject unknown versions.

#### Scenario: Missing schema_version is rejected
- **GIVEN** a persisted job record
- **WHEN** loading a `job.json` without `schema_version`
- **THEN** the store raises a data-corruption error

#### Scenario: Unknown schema_version is rejected
- **GIVEN** a persisted job record
- **WHEN** loading a `job.json` with `schema_version != 1`
- **THEN** the store raises a version error (treated as corruption for now)

### Requirement: Artifact rel_path is safe and job-relative

Artifacts MUST use job-relative `rel_path` and MUST NOT allow absolute paths or `..` traversal.

#### Scenario: Artifact rel_path forbids traversal
- **GIVEN** an artifact reference to be stored in `job.json`
- **WHEN** validating an artifact with `rel_path` containing `..` or an absolute path
- **THEN** validation fails
