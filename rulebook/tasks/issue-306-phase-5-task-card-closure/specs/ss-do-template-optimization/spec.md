# Delta Spec: Task card closure (Phase 5.9 + 5.10)

## Purpose

Ensure Phase 5 task cards remain auditable after delivery by recording completion state and linking merged PRs and run logs.

## Requirements

### Requirement: Task cards MUST be closed with completion evidence after merge

Task cards for Phase 5.9 and Phase 5.10 MUST have acceptance checklists checked and MUST include a `## Completion` section that links the merged PR and the corresponding run log.

#### Scenario: Completion section is present
- **GIVEN** a merged PR for a Phase 5 task card
- **WHEN** inspecting the task card file
- **THEN** the acceptance checklist items are marked `[x]`
- **AND** a `## Completion` section exists with PR + run log links

