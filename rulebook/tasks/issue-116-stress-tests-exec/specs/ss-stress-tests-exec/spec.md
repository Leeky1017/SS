# Spec: ss-stress-tests-exec

## Purpose

Make the stress suite faithfully execute queued jobs, so load and long-run tests reflect the intended
end-to-end scenario (enqueue + execute + query).

## Requirements

### Requirement: Stress tests drain the worker queue

Stress scenario tests that enqueue jobs MUST ensure workers actually process those jobs to a terminal
status within a bounded timeout.

#### Scenario: Load test waits for configured runs to finish
- **GIVEN** `SS_RUN_STRESS_TESTS=1`
- **WHEN** the load test enqueues `SS_STRESS_RUNS` jobs
- **THEN** the test waits until those jobs reach terminal status before stopping worker threads

#### Scenario: Stability loop drains enqueued jobs
- **GIVEN** `SS_RUN_STRESS_TESTS=1`
- **WHEN** the stability test enqueues one job per iteration
- **THEN** the worker queue is drained during the loop to avoid unbounded growth

