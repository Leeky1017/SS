# Spec (delta): ss-cursor-plans

## Purpose

Define a lightweight, repo-local convention for persisting Cursor plan artifacts under `.cursor/plans/` so that remediation planning can be shared and referenced in PRs/run logs.

## Requirements

### Requirement: Audit/remediation plans MAY be committed under `.cursor/plans/`

SS MAY store non-canonical planning artifacts under `.cursor/plans/` when they are needed for collaboration and delivery tracking.

Constraints:
- These files MUST NOT contain secrets (tokens, API keys, credentials, PII/raw data dumps).
- These files MUST NOT be treated as canonical project documentation (canonical docs remain under `openspec/specs/`).

#### Scenario: A plan is persisted for delivery
- **GIVEN** an internal analysis/remediation plan
- **WHEN** the plan needs to be shared across contributors
- **THEN** it can be added under `.cursor/plans/` and referenced by `openspec/_ops/task_runs/ISSUE-<N>.md`

