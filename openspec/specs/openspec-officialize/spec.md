# Spec: openspec-officialize

## Purpose

Make SS OpenSpec documents conform to the official `@fission-ai/openspec` CLI structure and strict validation, so specs become enforceable “law” in CI.

## Requirements

### Requirement: Add official OpenSpec root files and folders

The repository MUST include:
- `openspec/project.md`
- `openspec/AGENTS.md`
- `openspec/changes/archive/`

#### Scenario: OpenSpec root layout exists
- **WHEN** browsing the repository
- **THEN** the above files and folders exist under `openspec/`

### Requirement: Specs pass official strict validation

All active specs under `openspec/specs/` MUST pass:
- `openspec validate --specs --strict --no-interactive`

#### Scenario: Specs validate in strict mode
- **WHEN** running `openspec validate --specs --strict --no-interactive`
- **THEN** the command exits with code `0`

### Requirement: CI enforces OpenSpec validation

The `ci` workflow MUST run OpenSpec validation before lint/tests, by installing the official CLI and executing:
- `openspec validate --specs --strict --no-interactive`

#### Scenario: PR checks include strict OpenSpec validation
- **WHEN** a PR is opened
- **THEN** the `ci` check fails if OpenSpec validation fails

