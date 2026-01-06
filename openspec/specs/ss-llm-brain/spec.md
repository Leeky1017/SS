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

