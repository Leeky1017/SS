# Spec Delta: Phase 5.1 core T01–T20 (Issue #193)

## Requirement: Each template contains a best-practice review record

For templates in scope (`T01`–`T20`), the do-file MUST include a short review record in the header comment block that documents:
- methodological/best-practice changes (what + why),
- SSC dependency decisions (removed/replaced, or exception with rationale),
- output tooling decisions (e.g., `putdocx` vs CSV export),
- error-handling policy decisions (warn vs fail) for key input checks.

## Scenario: Review record is visible and auditable

- **GIVEN** a template do-file in scope
- **WHEN** reviewing the file header
- **THEN** a Phase 5.1 review record exists
- **AND** it states SSC dependency status and output tooling choices in a human-auditable way.

