# Spec: ss-production-readiness-ux-audit (issue-124)

## Purpose

Produce a production-readiness audit focused on the end-to-end user experience loop (input → understand → confirm → execute → output → recoverability).

## Requirements

### Requirement: Audit report is created

The audit MUST produce a new report under `Audit/` that includes:
- UX-loop checklist results (6 phases)
- Blockers vs nice-to-haves
- A final verdict: Ready / Conditional Ready / Not Ready (with reasons)

#### Scenario: Audit report exists and is complete
- **GIVEN** the task is delivered
- **WHEN** inspecting the `Audit/` directory
- **THEN** it contains a new production readiness audit report covering the 6 phases and a final verdict

### Requirement: Blockers have actionable task cards

For each blocker identified in the audit, there MUST be a corresponding OpenSpec task card with clear acceptance criteria and priority.

#### Scenario: Each blocker has a task card
- **GIVEN** the audit report lists a blocker item
- **WHEN** searching under `openspec/specs/**/task_cards/`
- **THEN** a corresponding task card exists and references `Issue: #124`

### Requirement: Evidence is traceable

The run log MUST be updated with key commands and outputs used during the audit.

#### Scenario: Run log contains commands and key outputs
- **GIVEN** the task is delivered
- **WHEN** opening `openspec/_ops/task_runs/ISSUE-124.md`
- **THEN** it includes the audit runs and the PR link (after PR creation)

### Requirement: Local verification passes

Local verification MUST pass for the delivery branch.

#### Scenario: Lint and tests succeed
- **GIVEN** the repo is checked out on the delivery branch
- **WHEN** running local verification commands
- **THEN** `ruff check .` and `pytest -q` succeed
