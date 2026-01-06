# Spec: ss-observability

## Purpose

Define SS observability contracts (structured logging and required fields) so failures are diagnosable without leaking sensitive data.

## Requirements

### Requirement: Logging uses stable event codes and required context fields

SS MUST define stable event codes (e.g., `SS_XXX_YYY`) and SS MUST include required context fields in logs, at least `job_id` and (when applicable) `run_id` and `step`.

#### Scenario: Observability contract defines event codes and fields
- **WHEN** reading `openspec/specs/ss-observability/README.md`
- **THEN** it lists the event code convention and required fields

### Requirement: Log level is configured via src/config.py

SS MUST configure log level from `src/config.py` and MUST NOT scatter direct environment variable reads across the codebase.

#### Scenario: Log level source is explicit
- **WHEN** reviewing logging initialization requirements
- **THEN** it states that log level comes from `src/config.py`

