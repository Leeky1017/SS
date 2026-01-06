# Spec: ss-security

## Purpose

Define SS security red lines (path safety, execution isolation, and sensitive data redaction) to prevent common vulnerabilities early.

## Requirements

### Requirement: Artifact download is path-safe

SS MUST prevent path traversal and symlink escapes when serving artifact downloads, and SS MUST reject unsafe paths such as absolute paths or `..` traversal.

#### Scenario: Security contract forbids traversal
- **WHEN** reading `openspec/specs/ss-security/README.md`
- **THEN** it states that artifact paths cannot escape the job directory

### Requirement: Runner execution is isolated to the run workspace

SS MUST constrain do-file generation and runner execution to the job/run workspace and MUST NOT allow writes outside the run attempt directory.

#### Scenario: Runner isolation is required
- **WHEN** reviewing runner security requirements
- **THEN** it requires working directory isolation and forbids cross-directory writes

### Requirement: Logs and LLM artifacts do not leak sensitive values

SS MUST redact secrets, tokens, and privacy identifiers from logs and LLM artifacts, and SS MUST avoid storing raw input data dumps by default.

#### Scenario: Redaction is mandatory
- **WHEN** persisting logs or LLM artifacts
- **THEN** sensitive values are not stored in plaintext

