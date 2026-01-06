# Spec: ss-do-template-library

## Purpose

Define how SS reuses and manages a do-template library (including legacy `stata_service/tasks`) as a versioned data asset with safe execution boundaries.

## Requirements

### Requirement: Do template library is a data asset, not a task system

If SS integrates a do-template library, SS MUST treat it as a versioned data asset and MUST NOT treat it as OpenSpec tasks or Rulebook tasks.

#### Scenario: Naming avoids task-system confusion
- **WHEN** placing the template library in the SS repository
- **THEN** the directory name avoids `tasks/` to prevent confusion with `openspec/tasks` and `rulebook/tasks`

### Requirement: Template loading uses an explicit port

SS MUST load templates via an explicit repository/loader port (e.g., `DoTemplateRepository`) so the library location can be configured and tested.

#### Scenario: Library can be loaded from a configured path
- **WHEN** SS is configured to point at a template library directory
- **THEN** templates and metadata can be enumerated and fetched via the loader port

### Requirement: Template execution is constrained and auditable

Template execution MUST be constrained to the job/run workspace and MUST archive template source, metadata, parameters, logs, and declared outputs as artifacts.

#### Scenario: Execution produces complete evidence
- **WHEN** a template-based run is executed
- **THEN** artifacts include template source, meta, parameter map, stdout/stderr, and log files

