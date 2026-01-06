# Spec: ss-llm-brain

## Purpose

Define SS LLM Brain contracts (plan schema + prompt/response artifacts + safety) so LLM behavior is auditable and replaceable.

## Requirements

### Requirement: LLM provider is replaceable

The LLM provider MUST be an infra adapter behind a port, and domain logic MUST NOT bind to any specific SDK.

#### Scenario: LLM dependency is injected
- **WHEN** a domain service uses LLM capability
- **THEN** it depends on an injected `LLMClient` port

### Requirement: LLM calls are fully traced as artifacts

Each LLM call MUST write prompt/response/meta artifacts and MUST index them in the job artifacts index.

#### Scenario: LLM trace artifacts are required
- **WHEN** an LLM request is executed
- **THEN** prompt/response/meta are stored as artifacts and are discoverable via `job.json`

#### Artifact layout (v1, minimal)

- Root: `jobs/<job_id>/artifacts/llm/<llm_call_id>/`
- Files:
  - `prompt.txt` (kind: `llm.prompt`, redacted text)
  - `response.txt` (kind: `llm.response`, redacted text; empty if no response)
  - `meta.json` (kind: `llm.meta`, structured metadata)

`meta.json` MUST include (v1):
- `schema_version` (int, `1`)
- `llm_call_id` (string)
- `operation` (string, e.g. `draft_preview`)
- `started_at` / `ended_at` (ISO8601 string)
- `duration_ms` (int)
- `ok` (bool)
- `model` (string)
- `temperature` (number | null)
- `seed` (number | string | null, redacted/fingerprinted if sensitive)
- `prompt_fingerprint` / `response_fingerprint` (string; sha256 hex)
- `prompt_token_estimate` / `response_token_estimate` (int)
- `error_type` / `error_message` (string | null; present on failure, redacted)

### Requirement: LLM outputs are schema-bound

LLM outputs used for downstream behavior MUST be schema-bound (especially plans) and parse failures MUST be treated as error paths.

#### Scenario: Plan parsing failure is not silent
- **WHEN** an LLM plan output cannot be parsed/validated
- **THEN** the operation fails with a structured error and evidence artifacts

### Requirement: Redaction prevents sensitive leakage

Logs and LLM artifacts MUST NOT leak secrets, tokens, or privacy identifiers, and prompts MUST prefer summaries + fingerprints over raw data dumps.

#### Scenario: Redaction policy is applied
- **WHEN** storing logs or LLM artifacts
- **THEN** sensitive values are not persisted in plaintext

#### Redaction policy (v1, minimal)

- Never log raw prompt/response in application logs.
- Before persisting `prompt.txt` / `response.txt` / `meta.json` error fields:
  - redact bearer tokens (`Authorization: Bearer ...`)
  - redact API keys/tokens/secrets/passwords (common `key=value` patterns)
  - redact obvious key formats (e.g. `sk-...`)
  - redact absolute home paths (`/home/<user>/...`, `/Users/<user>/...`)
