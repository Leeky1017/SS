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

For roadmap sub-issues, SS MUST maintain `task_cards/` as “Issue blueprints” that summarize scope, dependencies, and acceptance, without replacing GitHub Issues or Rulebook tasks.

#### Scenario: Task cards exist for sub-issues
- **WHEN** browsing `openspec/specs/ss-roadmap/task_cards/`
- **THEN** it contains markdown files that map to roadmap sub-issues
