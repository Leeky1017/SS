# Spec: ss-worker-coverage (issue-418)

## Purpose

Protect worker critical paths (claim handling, retry decisions, and pre-run errors) with deterministic unit tests.

## Requirements

### Requirement: Worker internals are regression-protected by unit tests

SS MUST include unit tests that cover:
- claim handling for jobs (including no-job and already-claimed outcomes)
- retry/backoff decisions for failed runs
- pre-run validation errors producing structured failures (no silent pass)

#### Scenario: Worker claim handling is exercised
- **GIVEN** a worker claim handler with fake dependencies
- **WHEN** it handles claim outcomes (success / no job / conflict)
- **THEN** the resulting state transitions and logs are deterministic and asserted by tests

#### Scenario: Worker retry logic is exercised
- **GIVEN** a retry policy and a failed attempt
- **WHEN** the retry logic evaluates the failure
- **THEN** it either schedules a retry or marks the run terminal, as asserted by tests

