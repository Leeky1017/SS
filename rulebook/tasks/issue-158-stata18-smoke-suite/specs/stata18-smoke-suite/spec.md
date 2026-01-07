# Spec Delta: issue-158-stata18-smoke-suite

## Purpose

Define a reusable Stata 18 smoke-suite manifest + local runner that emits auditable evidence, while ensuring CI can still enforce strong static gates when Stata cannot run.

## Requirements

### Requirement: Smoke-suite manifest is versioned and schema-validated

The repository MUST include a versioned smoke-suite manifest under the do-template library, and CI MUST validate it against a JSON Schema.

#### Scenario: Manifest can be validated without Stata
- **GIVEN** a smoke-suite manifest file exists in the repo
- **WHEN** CI runs unit tests
- **THEN** the smoke-suite manifest validates against its schema
- **AND** every referenced template ID and fixture path exists

### Requirement: Local smoke suite writes a structured report

SS MUST provide a local command that executes the smoke suite and writes a single structured JSON report with per-template outcomes.

#### Scenario: Local run produces auditable output
- **GIVEN** a smoke-suite manifest exists locally
- **WHEN** running `ss run-smoke-suite`
- **THEN** a report is written with pass/fail/missing-deps outcomes
- **AND** per-template outputs are referenced (archived + missing outputs)

### Requirement: CI gate remains strong when Stata cannot run

If Stata cannot be executed in CI, CI MUST still block manifest/contract regressions via static validation.

#### Scenario: CI fails on manifest drift
- **GIVEN** the smoke-suite manifest contains invalid references
- **WHEN** the manifest references a missing template ID, fixture path, or required parameter
- **THEN** CI fails with a deterministic validation error
