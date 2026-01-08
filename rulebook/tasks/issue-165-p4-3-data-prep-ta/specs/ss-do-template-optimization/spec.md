# Delta Spec: Phase 4.3 Data Prep (TA01-TA14)

## Purpose

Define the concrete, checkable deltas for Phase 4.3: data-prep templates `TA01`-`TA14` must be runnable under the Stata 18 smoke-suite harness with fixtures, emitting consistent pipe-delimited anchors and explicit failure diagnostics.

## Requirements

### Requirement: TA01-TA14 are runnable under the Stata 18 smoke-suite harness

#### Scenario: Each TA template runs with its fixture set
- **GIVEN** `assets/stata_do_library/smoke_suite/manifest.1.0.json` contains entries for `TA01`-`TA14`
- **WHEN** the smoke-suite harness stages fixtures and runs each template
- **THEN** every case finishes without runtime failures (`status=passed`)

### Requirement: TA01-TA14 anchors are normalized and machine-parseable

#### Scenario: No legacy `SS_*:` anchors within TA01-TA14
- **WHEN** reading the `result.log` for a TA template run
- **THEN** anchors use pipe-delimited `SS_*|k=v` format
- **AND** failures/warnings are recorded via `SS_RC|code=...|cmd=...|msg=...|severity=...`

### Requirement: SSC dependencies fail fast with structured anchors

#### Scenario: Missing SSC dependency yields `missing_deps` in the smoke suite
- **GIVEN** a required SSC package is not installed
- **WHEN** a TA template checks dependencies at startup
- **THEN** it emits `SS_DEP_CHECK|pkg=<pkg>|source=ssc|status=missing`
- **AND** it emits `SS_RC|code=199|cmd=which <pkg>|msg=dependency_missing|severity=fail`
- **AND** it exits with `199`

