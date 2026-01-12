# Spec: ss-ci-coverage-gate (issue-415)

## Purpose

Prevent silent test coverage regressions by enforcing a minimum baseline in CI.

## Requirements

### Requirement: CI enforces a baseline coverage threshold

SS CI MUST run pytest with coverage for `src` and MUST fail the build when overall coverage drops below the baseline threshold.

Baseline threshold (initial): 75%.

#### Scenario: CI fails when coverage drops below threshold
- **GIVEN** CI executes tests with coverage enabled for `src`
- **WHEN** overall coverage is below 75%
- **THEN** the job fails (via `--cov-fail-under=75`)
