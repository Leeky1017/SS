# Delta Spec: Phase 4.9 Survival + Multivariate (TI01-TI11, TJ01-TJ06)

## Purpose

Define the concrete, checkable deltas for Phase 4.9: survival + multivariate templates `TI01`-`TI11` and `TJ01`-`TJ06` must be runnable under the Stata 18 smoke-suite harness with fixtures, emitting consistent pipe-delimited anchors and explicit failure diagnostics.

## Requirements

### Requirement: TI01-TI11 and TJ01-TJ06 are runnable under the Stata 18 smoke-suite harness

#### Scenario: Each template runs with its fixture set
- **GIVEN** a TI/TJ-scoped smoke-suite manifest contains entries for `TI01`-`TI11` and `TJ01`-`TJ06`
- **WHEN** the smoke-suite harness stages fixtures and runs each template
- **THEN** every case finishes without runtime failures (`status!=failed`)

### Requirement: TI/TJ anchors are normalized and machine-parseable

#### Scenario: No legacy `SS_*:` anchors within TI/TJ templates
- **WHEN** reading `result.log` for a TI/TJ template run
- **THEN** anchors use pipe-delimited `SS_*|k=v` format
- **AND** failures/warnings are recorded via `SS_RC|code=...|cmd=...|msg=...|severity=...`

### Requirement: Common survival/multivariate failure modes are explicit (warn/fail with SS_RC)

#### Scenario: stset requirements and encoding issues are surfaced
- **GIVEN** inputs violate survival requirements (missing time/censor, invalid coding, or stset preconditions)
- **WHEN** the template validates inputs before running survival/multivariate commands
- **THEN** it emits a structured `SS_RC|...|severity=<warn|fail>` with actionable context
- **AND** it does not silently proceed after `capture` without checking `_rc`

