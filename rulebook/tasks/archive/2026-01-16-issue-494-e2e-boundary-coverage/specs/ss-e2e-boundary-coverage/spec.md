# Spec: ss-e2e-boundary-coverage

## Purpose

Expand the E2E suite to cover the `tests/e2e/COVERAGE.md` “known gaps”, ensuring boundary behavior is stable and
observable across:
- input parsing / preview,
- LLM output validation,
- execution failure paths.

## Requirements

### Requirement: Input preview handles Excel/CSV boundaries

Input preview MUST handle boundary Excel/CSV cases with stable error codes/messages.

#### Scenario: Password-protected Excel is rejected with clear error
- **GIVEN** an encrypted/password-protected Excel workbook upload
- **WHEN** requesting `GET /v1/jobs/{job_id}/inputs/preview`
- **THEN** the API returns `400 INPUT_PARSE_FAILED` with a user-friendly message explaining encryption is unsupported

#### Scenario: Hidden sheets follow a consistent strategy
- **GIVEN** an Excel workbook with hidden sheets
- **WHEN** requesting `GET /v1/jobs/{job_id}/inputs/preview`
- **THEN** response `sheet_names` follows the implemented strategy (e.g., visible-only), and tests assert it

#### Scenario: Formula cells produce stable preview values
- **GIVEN** an Excel workbook containing formula cells
- **WHEN** requesting `GET /v1/jobs/{job_id}/inputs/preview`
- **THEN** preview returns either cached computed values or raw formula strings (current behavior is asserted)

#### Scenario: Large dataset bounds are explicit
- **GIVEN** a “large enough” dataset upload
- **WHEN** requesting preview
- **THEN** either completes within a bounded time, OR returns a stable limit error (e.g., `413`/`400` with explicit code)

#### Scenario: Pathological column names are normalized predictably
- **GIVEN** columns with long names / special characters / numeric-only names
- **WHEN** requesting preview
- **THEN** columns are either normalized safely or rejected with a stable error code

### Requirement: Draft preview rejects malformed/empty LLM output

Draft preview MUST validate structured LLM output and reject invalid/empty payloads with stable errors.

#### Scenario: Non-JSON or truncated JSON returns a stable 502
- **GIVEN** the LLM responds with malformed JSON
- **WHEN** requesting `GET /v1/jobs/{job_id}/draft/preview`
- **THEN** the API returns `502 LLM_RESPONSE_INVALID` and logs enough context for debugging (no raw prompt leakage)

#### Scenario: Missing required structured fields is handled explicitly
- **GIVEN** the LLM returns JSON missing required fields
- **WHEN** requesting draft preview
- **THEN** behavior is explicit and tested (defaults or a stable error code)

#### Scenario: Empty draft text is rejected
- **GIVEN** the LLM returns an empty `draft_text`
- **WHEN** requesting draft preview
- **THEN** the API rejects it with a stable error (no empty draft can advance to confirm/run)

### Requirement: Execution failures are observable

Execution failures MUST be traceable via job status and run artifacts (meta/stderr/error JSON).

#### Scenario: Stata timeout results in failed job with traceable error
- **GIVEN** a run attempt that times out
- **WHEN** worker processes the job
- **THEN** job status becomes `failed` and run error artifacts include `STATA_TIMEOUT`

#### Scenario: Do-file syntax error results in failed job with traceable error
- **GIVEN** a run attempt with a do-file syntax error
- **WHEN** worker processes the job
- **THEN** job status becomes `failed` and run error artifacts include `STATA_NONZERO_EXIT` (or a more specific code)
