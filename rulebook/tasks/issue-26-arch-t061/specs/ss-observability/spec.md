# Spec: issue-26-arch-t061 (observability logging baseline)

## Purpose

Define the delta requirements for ARCH-T061: structured logging contract is enforced by a shared
logging initializer and driven by `src/config.py`.

## Requirements

### Requirement: Entrypoints configure structured logging from src/config.py

SS MUST configure logging in API/worker/CLI entrypoints via a shared initializer and MUST source
log level from `Config.log_level` (loaded by `src/config.py`).

#### Scenario: log_level is not hard-coded
- **WHEN** reviewing entrypoints (`src/main.py`, `src/worker.py`, `src/cli.py`)
- **THEN** they call a shared logging initializer and do not hard-code log level strings

### Requirement: Logs always include required context keys

Each log record MUST include the context keys `job_id`, `run_id`, and `step` (null allowed when not
applicable), and the event code MUST follow `SS_<AREA>_<ACTION>`.

#### Scenario: log output includes required keys
- **WHEN** emitting a log line without any `extra`
- **THEN** the serialized output still contains `job_id`, `run_id`, and `step` keys
