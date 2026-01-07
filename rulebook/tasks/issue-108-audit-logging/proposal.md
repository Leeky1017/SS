# Proposal: issue-108-audit-logging

## Why
Audit remediation requires answering “who did what, when” for state-changing operations. Today SS emits lifecycle logs, but lacks a stable audit event schema for operator aggregation and incident response.

## What Changes
ADDED:
- Domain audit port + event schema for state-changing operations.
- Infra audit logger adapter emitting structured JSON log events (ship-ready).

MODIFIED:
- Job lifecycle services (API-triggered and worker) emit audit events on user/system actions and state transitions.
- Observability docs describe correlation keys (request/job identifiers).

## Impact
- Affected specs: `openspec/specs/ss-observability/README.md`
- Affected code: `src/domain/*`, `src/api/*`, `src/infra/*`
- Breaking change: NO
- User benefit: Operators can correlate user/system actions with job state changes via audit events.
