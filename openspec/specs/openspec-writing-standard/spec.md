# Spec: openspec-writing-standard

## Purpose

Define enforceable spec-writing rules for SS that match the official `@fission-ai/openspec` strict validator, so specs can be treated as non-negotiable “law”.

## Requirements

### Requirement: Spec format MUST pass official strict validation

All active specs under `openspec/specs/<spec-id>/spec.md` MUST pass:
- `openspec validate --specs --strict --no-interactive`

#### Scenario: Strict validation is the gate
- **WHEN** `openspec validate --specs --strict --no-interactive` is executed
- **THEN** it exits with code `0`

### Requirement: Every spec MUST use the official structure

Every spec file MUST include:
- `## Purpose`
- `## Requirements`
- At least one `### Requirement: ...`
- At least one `#### Scenario: ...` with `- **WHEN**` and `- **THEN**`

#### Scenario: Spec contains required headings
- **WHEN** a spec is validated
- **THEN** it contains `## Purpose` and `## Requirements`

### Requirement: Requirements MUST be verifiable

Each Requirement MUST be testable by at least one of:
- a command (`ruff check .`, `pytest -q`, `openspec validate ...`)
- a test name
- a concrete evidence file path (e.g., `openspec/_ops/task_runs/ISSUE-N.md`)

#### Scenario: Requirement provides a verifiable path
- **WHEN** a requirement is reviewed
- **THEN** reviewers can point to a command or evidence path to validate it

### Requirement: No placeholders

Specs MUST NOT contain placeholders like:
- `(fill)` / `<fill...>` / `TODO` / `TBD`

#### Scenario: Placeholders are rejected
- **WHEN** a spec contains placeholder text
- **THEN** strict validation (or CI guard) fails
