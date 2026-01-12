# Spec: ss-do-template-library

## Purpose

Define how SS reuses and manages a do-template library (including legacy `stata_service/tasks`) as a versioned data asset with safe execution boundaries.

## Requirements

### Requirement: Do template library is a data asset, not a task system

If SS integrates a do-template library, SS MUST treat it as a versioned data asset and MUST NOT treat it as OpenSpec tasks or Rulebook tasks.

#### Scenario: Naming avoids task-system confusion
- **WHEN** placing the template library in the SS repository
- **THEN** the directory name avoids `tasks/` to prevent confusion with `openspec/tasks` and `rulebook/tasks`

### Requirement: Library layout is stable and index-driven

SS MUST load templates from a library root directory that contains an index file and a stable `do/` layout.

#### Scenario: Index-driven filesystem layout
- **GIVEN** a library root directory
- **WHEN** loading templates
- **THEN** SS reads `DO_LIBRARY_INDEX.json` and resolves:
  - do-file: `do/<do_file>`
  - meta: `do/meta/<do_file_stem>.meta.json`

### Requirement: Template loading uses an explicit port

SS MUST load templates via an explicit repository/loader port (e.g., `DoTemplateRepository`) so the library location can be configured and tested.

#### Scenario: Library can be loaded from a configured path
- **WHEN** SS is configured to point at a template library directory
- **THEN** templates and metadata can be enumerated and fetched via the loader port

### Requirement: Placeholder replacement is deterministic and validated

SS MUST render do-files deterministically from the same template + parameter map, and MUST fail fast when required parameters are missing.

#### Scenario: Missing required parameter fails with structured error
- **GIVEN** a template meta that declares a required parameter (e.g. `__DEPVAR__`)
- **WHEN** running without providing that parameter
- **THEN** SS fails with a structured error code and archives the run attempt evidence

### Requirement: Meta tags support data-shape auditing (wide/long/panel)

When a template is shape-sensitive, its `do/meta/*.meta.json` MUST declare the relevant data shape in `tags`:
- `wide` (expects wide-style paired/multi-column structure)
- `long` (expects long/tidy structure, including panel-ready long form)
- `panel` (requires panel operations such as `xtset`, `xtreg`, etc)

#### Scenario: Shape-sensitive tags are present in meta
- **WHEN** reviewing meta for `T14` (paired before/after) and `T30/T31` (panel setup/FE)
- **THEN** `T14.tags` includes `wide` and `T30/T31.tags` include `long` + `panel`

### Requirement: Common placeholder aliases are supported

SS MUST treat `__ID_VAR__` and `__PANELVAR__` as aliases during rendering so callers can provide either name for panel identifiers.

#### Scenario: ID variable alias renders required placeholder
- **GIVEN** a template that requires `__PANELVAR__`
- **WHEN** a caller provides only `__ID_VAR__`
- **THEN** rendering succeeds and replaces `__PANELVAR__` with the provided identifier

### Requirement: Template execution is constrained and auditable

Template execution MUST be constrained to the job/run workspace and MUST archive template source, metadata, parameters, logs, and declared outputs as artifacts.

#### Scenario: Execution produces complete evidence
- **WHEN** a template-based run is executed
- **THEN** artifacts include template source, meta, parameter map, stdout/stderr, and log files
- **AND** declared outputs are copied into the run `artifacts/outputs/` directory (no traversal, no absolute paths)
