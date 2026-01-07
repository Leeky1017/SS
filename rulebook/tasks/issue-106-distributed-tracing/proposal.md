# Proposal: issue-106-distributed-tracing

## Why
The audit found no distributed tracing support, which makes it hard to correlate API requests, worker execution, and downstream calls for a single job.

## What Changes
- Add OpenTelemetry-based distributed tracing with configurable exporters (OTel/Jaeger/Zipkin via deployment config).
- Propagate trace context from API → queue → worker; persist `trace_id` on each job for correlation.
- Extend structured logs to include `trace_id` / `span_id` without leaking sensitive data.

## Impact
- Affected code: API startup, worker loop, queue records, logging formatter, job model
- Breaking change: NO (new fields are additive and optional)

