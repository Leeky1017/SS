# Spec: ss-roadmap

## Purpose

Define the SS roadmap structure and how task cards map roadmap items into agent-readable execution blueprints.

## Requirements

### Requirement: Roadmap is tracked by GitHub Issues

SS roadmap MUST be tracked by GitHub Epics and sub-issues, and each implementation PR MUST reference its Issue ID.

#### Scenario: Issue is the task ID
- **WHEN** a new change is delivered
- **THEN** it is linked to a GitHub Issue `#N` and the PR body contains `Closes #N`

### Requirement: Task cards document each roadmap sub-issue

For roadmap sub-issues, SS MUST maintain task cards as “Issue blueprints” that summarize scope, dependencies, and acceptance, without replacing GitHub Issues or Rulebook tasks.
Task cards MUST be stored under the owning contract spec directory:
- `openspec/specs/<spec-id>/task_cards/<card>.md`
SS MUST maintain a central index at:
- `openspec/specs/ss-roadmap/task_cards_index.md`

#### Scenario: Task cards exist for sub-issues
- **WHEN** browsing `openspec/specs/ss-roadmap/task_cards_index.md`
- **THEN** it lists the task card paths for the current roadmap sub-issues
