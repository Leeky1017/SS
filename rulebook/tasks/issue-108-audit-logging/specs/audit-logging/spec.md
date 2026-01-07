# Spec: issue-108-audit-logging

## Purpose

Define the SS audit logging contract for state-changing operations, so operators can answer “who did what, when” and correlate actions with request/job identifiers.

## Requirements

### Requirement: State-changing operations emit structured audit events

SS MUST emit structured audit events for state-changing operations (at minimum job confirmation and run triggers), including timestamp, actor identity, resource identifiers, action, and result status.

#### Scenario: Job confirmation emits an audit event
- **GIVEN** a job exists and is eligible for confirmation
- **WHEN** a user confirms the job and the service queues a run
- **THEN** an audit event is emitted with `action=job.confirm`, `job_id`, `actor`, and a status transition (e.g., `confirmed -> queued`)

#### Scenario: Job run trigger emits an audit event
- **GIVEN** a job exists and is eligible to be queued
- **WHEN** a user triggers a job run
- **THEN** an audit event is emitted with `action=job.run.trigger`, `job_id`, `actor`, and the resulting status

### Requirement: Audit events are correlatable

SS audit events MUST include correlation identifiers so operators can join audit events with request logs and job lifecycle logs.

#### Scenario: Audit events share identifiers with request/job logs
- **GIVEN** request logs and audit logs are shipped to the same log store
- **WHEN** reviewing logs for a given `job_id` or `request_id`
- **THEN** audit events can be filtered and joined using the same identifiers
