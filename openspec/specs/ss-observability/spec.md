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

### Requirement: Logs include trace correlation fields

When distributed tracing is enabled, SS logs MUST include trace correlation fields so logs can be joined with traces:
- `trace_id` (W3C trace ID, 32 hex chars)
- `span_id` (current span ID, 16 hex chars)

These fields MUST NOT include sensitive data and MUST be safe to export to centralized logging.

#### Scenario: Trace-enabled logs include correlation fields
- **WHEN** a request triggers a job and the worker processes it with tracing enabled
- **THEN** logs emitted during the lifecycle include `job_id` and `trace_id`

### Requirement: Trace context propagates across API and worker boundaries

SS MUST propagate trace context from API → queue → worker so a single job can be followed end-to-end in a distributed trace.

Propagation MUST use standard W3C trace context headers (`traceparent`, `tracestate`) and MUST NOT encode job contents, prompts, or user input into trace context.

#### Scenario: Worker spans continue the API job trace
- **WHEN** a job is enqueued by the API and later claimed by a worker
- **THEN** the worker starts spans as children of the enqueued trace context
