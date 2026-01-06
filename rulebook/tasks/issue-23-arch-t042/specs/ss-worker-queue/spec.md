# Spec: issue-23-arch-t042 (worker execution)

## Purpose

Define the delta requirements for ARCH-T042: worker loop executes queued jobs with per-attempt run
directories and bounded retries.

## Requirements

### Requirement: Worker is a standalone entrypoint

Worker MUST be runnable via `python -m src.worker` and MUST process queued jobs without FastAPI.

#### Scenario: Worker can run and process one queued job
- **WHEN** the queue contains a queued job
- **THEN** the worker claims it and persists a run attempt record

### Requirement: Each attempt creates a run directory

Each execution attempt MUST create a new `runs/<run_id>/` directory and MUST persist attempt
artifacts under it.

#### Scenario: Run directory exists after attempt
- **WHEN** a job attempt completes (success or failure)
- **THEN** `jobs/<job_id>/runs/<run_id>/artifacts/` contains metadata/artifacts

### Requirement: Retries are bounded and configurable

Retry/backoff and max attempts MUST be configurable via `src/config.py`.

#### Scenario: Worker stops retrying after max attempts
- **WHEN** repeated failures reach the configured attempt limit
- **THEN** the job ends in `failed` and preserves attempt artifacts

