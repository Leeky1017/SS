# Scalability: Queue throughput + scale path

## Background

The audit flagged that the file-backed queue has an unclear throughput ceiling and lacks a documented scale path for higher worker counts and higher job throughput.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “队列吞吐量设计不清晰”

## Goal

Define a practical queue scalability plan (including throughput targets, failure modes, and a migration path to a scalable queue backend if needed).

## Dependencies & parallelism

- Hard dependencies: `phase-2__distributed-storage-evaluation.md` (queue/backend choices should align with storage decisions)
- Parallelizable with: ops track tasks

## Acceptance checklist

- [ ] Define throughput targets and constraints (jobs/min, p95 latency, worker count assumptions)
- [ ] Document the queue backend options and recommend a default for production
- [ ] Define the rollout/migration plan, including how to test and validate throughput
- [ ] Ensure any chosen design preserves single-claimer semantics and bounded retries
- [ ] Implementation run log records evidence of measurement and decision

## Estimate

- 8-12h

