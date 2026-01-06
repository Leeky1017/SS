# Spec (Delta): issue-27-arch-t062 — ss-security

## Requirements

### Requirement: Artifact path resolution is safe (read + write)

All artifact paths MUST be job-relative and MUST NOT allow:
- absolute paths
- `..` traversal
- symlink escapes outside `jobs/<job_id>/`

#### Scenario: Unsafe artifact download is rejected
- **WHEN** an artifact download is requested with unsafe path components
- **THEN** SS rejects the request with a structured error (`ARTIFACT_PATH_UNSAFE`).

#### Scenario: Unsafe artifact write is rejected
- **WHEN** SS persists an artifact using an unsafe `rel_path`
- **THEN** the write is rejected and no data is written outside the job directory.

### Requirement: LLM artifacts and logs are redacted

SS MUST redact sensitive values before persisting LLM prompt/response/meta artifacts, and MUST avoid logging raw prompts/responses.

#### Scenario: Redaction removes tokens and home paths
- **WHEN** storing `prompt.txt` / `response.txt` / `meta.json` error fields
- **THEN** bearer tokens, key-like strings, and absolute home paths are not persisted in plaintext.

### Requirement: Runner execution is bounded

Stata runner execution MUST be bounded to the run attempt workspace and MUST reject clearly unsafe do-file content that could escape the workspace or execute shell commands.

#### Scenario: Unsafe do-file is rejected
- **WHEN** a do-file contains `shell`/`!` or absolute path writes
- **THEN** SS fails the attempt with a structured error and artifacts are still captured.
