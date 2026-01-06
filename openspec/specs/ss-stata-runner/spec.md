# Spec: ss-stata-runner

## Purpose

Define the SS Stata runner contract (do-file generation/execution/isolation/artifact capture) so analysis execution is safe and reproducible.

## Requirements

### Requirement: Stata execution is behind a single runner port

All Stata execution MUST be encapsulated behind a single `StataRunner` port with an explicit `RunResult`.

#### Scenario: Runner is the only execution boundary
- **WHEN** code needs to execute Stata work
- **THEN** it calls `StataRunner` instead of invoking subprocess directly from domain/API

### Requirement: Execution is isolated to the run attempt directory

Execution MUST be isolated inside the job run attempt directory and MUST NOT write outside it (no absolute paths, no traversal).

#### Scenario: Runner enforces working directory boundaries
- **WHEN** a do-file attempts unsafe file writes
- **THEN** SS rejects or contains it within the run attempt workspace

### Requirement: Do-file generation is deterministic

Do-file generation MUST be deterministic: the same plan and inputs MUST produce the same do-file output (stable ordering/format).

#### Scenario: Same plan yields same do-file
- **WHEN** generating a do-file twice from the same inputs
- **THEN** the generated do-file texts are identical

### Requirement: Failures are structured and archived

Failures MUST be captured as structured errors with `error_code` and MUST archive stderr/stdout/log/meta as artifacts for audit.

#### Scenario: Failure produces evidence artifacts
- **WHEN** a runner execution fails
- **THEN** artifacts include logs and error metadata for debugging

