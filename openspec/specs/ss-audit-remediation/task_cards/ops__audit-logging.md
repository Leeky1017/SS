# Ops: Audit logging (who did what)

## Background

The audit found missing audit logs, which blocks answering “who did what, when” for state-changing operations and operational investigations.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏审计日志”

## Goal

Define and emit audit events for state-changing operations and sensitive actions, with a stable schema that can be aggregated by operators.

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: all non-conflicting tasks

## Acceptance checklist

- [ ] Define an audit event schema (timestamp, action, resource identifiers, actor identity, changes)
- [ ] Emit audit events for a defined set of state-changing operations (at least job confirmation and run triggers)
- [ ] Ensure audit events are structured and can be shipped to an external log store
- [ ] Document how to correlate audit events with request/job identifiers
- [ ] Implementation run log records `ruff check .` and `pytest -q`

## Estimate

- 4-6h

