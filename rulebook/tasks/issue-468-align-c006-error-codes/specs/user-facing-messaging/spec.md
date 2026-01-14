# Spec: user-facing-messaging

## Purpose

Define SS user-visible messaging rules: never expose internal technical terms, and show all failures as numeric error codes with friendly hints.

## Requirements

### Requirement: User-visible messages MUST NOT expose internal technical terms

User-visible messages MUST avoid internal implementation terminology (including AI/ML, frontend/backend, API/JSON/HTTP, and internal field names like `draft`/`job_id`/`tenant`).

#### Scenario: UI copy is implementation-agnostic
- **GIVEN** the shipped frontend is used by a real user
- **WHEN** a user uses the shipped frontend to complete the minimum journey
- **THEN** the UI contains no internal technical terms

### Requirement: User-visible errors MUST be numeric-coded

User-visible errors MUST be shown in this format:
- `错误代号 EXXXX：<friendly description>`

The UI MUST NOT display backend `message`/`detail` directly.

#### Scenario: Backend failures are rendered as numeric codes
- **GIVEN** an operation fails with backend `error_code="LLM_CALL_FAILED"`
- **WHEN** the UI renders the failure
- **THEN** it shows `错误代号 E4001：...` (numeric code) instead of backend `message`/`detail`
