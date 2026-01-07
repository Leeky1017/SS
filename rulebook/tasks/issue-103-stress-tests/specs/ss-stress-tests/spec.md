# Spec: ss-stress-tests

## Purpose

Define the minimum, repeatable SS stress-test suite to validate performance and resource stability under
high concurrency, long runtimes, and boundary inputs.

## Requirements

### Requirement: Stress tests are present and runnable

Stress tests MUST exist under `tests/stress/` and MUST be runnable in a dedicated environment without
impacting default CI runtime.

#### Scenario: Stress suite is skipped by default
- **GIVEN** `SS_RUN_STRESS_TESTS` is not set to `1`
- **WHEN** running `pytest -q`
- **THEN** stress tests are skipped unless `SS_RUN_STRESS_TESTS=1` is set

#### Scenario: Stress suite can be enabled explicitly
- **GIVEN** the runtime environment can tolerate long-running tests
- **WHEN** running `SS_RUN_STRESS_TESTS=1 pytest -q tests/stress -s`
- **THEN** scenario 1/2/4 tests execute and write JSON reports under each test's `tmp_path`

### Requirement: Stress suite reports baseline metrics

Stress tests MUST collect and report baseline metrics:
- p99 latency
- error rate
- RSS memory usage
- open file descriptor count (best-effort on Linux via `/proc`)

#### Scenario: Scenario 1 validates load SLOs
- **GIVEN** `SS_RUN_STRESS_TESTS=1`
- **WHEN** running the load test with 100 users, 50 runs, and 200 queries
- **THEN** p99 latency and error rate are checked against configurable SLO thresholds
