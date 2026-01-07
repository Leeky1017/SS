# Ops: Distributed tracing (end-to-end)

## Background

The audit found no distributed tracing support, making it difficult to correlate API requests, worker execution, and downstream calls for a single job.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏分布式追踪支持”

## Goal

Add distributed tracing support that propagates trace context across API and worker boundaries and provides spans for key operations.

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: all non-conflicting tasks

## Acceptance checklist

- [x] Define trace context propagation strategy (how trace IDs flow from API to worker and into logs)
- [x] Instrument key operations with spans (job creation, queue claim, job execution, external calls)
- [x] Tracing export is configurable for deployment (collector/exporter configuration)
- [x] Ensure tracing does not leak sensitive data
- [x] Implementation run log records evidence of traces and the configuration used

## Estimate

- 4-6h

## Completion

- PR: https://github.com/Leeky1017/SS/pull/118
- Notes:
  - Each job persists `trace_id` and queue records propagate `traceparent` (API → queue → worker)
  - Logs include `trace_id`/`span_id` for correlation with OpenTelemetry spans
  - Tracing export is configured via `SS_TRACING_*` and can integrate with Jaeger/Zipkin via an OpenTelemetry Collector
- Run log: `openspec/_ops/task_runs/ISSUE-106.md`
