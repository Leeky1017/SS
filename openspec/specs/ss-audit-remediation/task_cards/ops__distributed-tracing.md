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

- [ ] Define trace context propagation strategy (how trace IDs flow from API to worker and into logs)
- [ ] Instrument key operations with spans (job creation, queue claim, job execution, external calls)
- [ ] Tracing export is configurable for deployment (collector/exporter configuration)
- [ ] Ensure tracing does not leak sensitive data
- [ ] Implementation run log records evidence of traces and the configuration used

## Estimate

- 4-6h

