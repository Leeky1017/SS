# Spec: ss-output-formatter-coverage (issue-420)

## Purpose

Protect output formatter behaviors (data conversions and structured error artifacts) with deterministic unit tests.

## Requirements

### Requirement: Output formatter data conversions are regression-protected

SS MUST include unit tests that cover:
- CSV → DTA conversion (happy path)
- DTA → CSV conversion (happy path)
- read/write failure producing `RunError(error_code="OUTPUT_FORMATTER_FAILED")`

#### Scenario: CSV to DTA conversion succeeds
- **GIVEN** a job workspace with a CSV export artifact
- **WHEN** the formatter produces DTA
- **THEN** it writes `output.dta` and returns an `ArtifactRef` with stable metadata

### Requirement: Output formatter error artifacts are idempotent and safe

SS MUST include unit tests that cover:
- returning `None` when an error artifact already exists
- returning `None` when writing fails (with a structured log emitted)

#### Scenario: Error artifact write is idempotent
- **GIVEN** an existing `error.json` in the run artifacts directory
- **WHEN** `write_run_error_artifact` is called
- **THEN** it returns `None` and does not overwrite the file

