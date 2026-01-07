# Proposal: issue-104-metrics-export

## Why
The SS audit found no metrics export, which blocks production monitoring and alerting for throughput, latency, error rate, and worker activity.

## What Changes
Add a Prometheus-format `/metrics` endpoint and minimal in-process metrics collectors for:
- job throughput (created/completed/failed)
- request latency (histogram for p50/p95/p99 via PromQL)
- worker activity (active jobs / worker loops)
- error rates (request errors + job execution errors)

## Impact
- Affected specs: `openspec/specs/ss-audit-remediation/task_cards/ops__metrics-export.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/`
- Breaking change: NO
- User benefit: production monitoring + alerting readiness
