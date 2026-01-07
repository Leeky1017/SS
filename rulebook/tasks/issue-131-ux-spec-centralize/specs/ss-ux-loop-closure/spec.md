# Spec: ss-ux-loop-closure (issue-131)

## Purpose

Centralize production-readiness UX-loop blockers into a single authoritative OpenSpec and remove scattered duplicates.

## Requirements

### Requirement: Dedicated OpenSpec MUST exist

The delivery MUST add a dedicated OpenSpec directory that describes the production-readiness UX-loop gaps and references the audit report.

#### Scenario: Dedicated spec exists
- **GIVEN** the delivery branch is checked out
- **WHEN** browsing `openspec/specs/ss-ux-loop-closure/`
- **THEN** `spec.md` exists and documents the UX-loop blockers and scope

### Requirement: UX blocker task cards MUST be centralized

The delivery MUST provide detailed task cards for UX-B001/B002/B003 under the dedicated OpenSpec and MUST reference the existing GitHub issues (#126-#128).

#### Scenario: Task cards are present and linked
- **GIVEN** the dedicated OpenSpec exists
- **WHEN** browsing `openspec/specs/ss-ux-loop-closure/task_cards/`
- **THEN** it contains task cards for UX-B001/B002/B003 that reference #126/#127/#128

### Requirement: Old scattered task cards MUST be removed

The delivery MUST delete the previously scattered UX-B001/B002/B003 task cards so only one authoritative copy remains.

#### Scenario: Old task cards are deleted
- **GIVEN** the delivery branch is checked out
- **WHEN** searching under `openspec/specs/` for old UX-B001/B002/B003 paths
- **THEN** the old scattered task card files do not exist

### Requirement: References MUST be updated

All in-repo references to the moved task cards MUST be updated to the new paths to avoid broken links.

#### Scenario: Audit report and run logs reference new paths
- **GIVEN** the delivery branch is checked out
- **WHEN** opening the production readiness audit report and relevant run logs
- **THEN** they reference the new `openspec/specs/ss-ux-loop-closure/task_cards/` paths

