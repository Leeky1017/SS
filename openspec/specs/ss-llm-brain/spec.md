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

- Root: `jobs/<shard>/<job_id>/artifacts/llm/<llm_call_id>/` (legacy: `jobs/<job_id>/artifacts/llm/<llm_call_id>/`)
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

#### Scenario: Plan parsing failure triggers rule fallback
- **WHEN** a plan generation response cannot be parsed/validated or contains unsupported step types
- **THEN** SS falls back to the existing rule-based plan and records `plan_source=rule_fallback` with a structured `fallback_reason` in `artifacts/plan.json`

### Requirement: Plan generation operation is schema-bound (v1)

The `plan.generate` LLM operation MUST return a versioned JSON object that can be parsed into plan steps.

#### Scenario: Plan generation returns JSON
- **GIVEN** a job requirement, draft context, selected templates, data schema, and constraints (e.g., `max_steps`)
- **WHEN** SS asks the LLM to generate a plan (`operation=plan.generate`)
- **THEN** the LLM returns ONLY a JSON object matching the plan generation response schema

### Requirement: Draft preview output schema is versioned (v2)

The `draft_preview` LLM operation MUST return a versioned JSON object. v2 extends v1 with panel dimensions, clustering, fixed effects, interaction terms (e.g., DID), and IV instruments.

#### Scenario: Draft preview output v2 is parseable
- **WHEN** `draft_preview` returns a v2 JSON object (`schema_version=2`)
- **THEN** SS can parse and use extracted fields including `time_var`, `entity_var`, `cluster_var`, `fixed_effects[]`, `interaction_terms[]`, `instrument_var`, and `analysis_hints[]`

#### Scenario: Draft preview v1 output remains supported
- **WHEN** `draft_preview` returns a v1 JSON object without `schema_version`
- **THEN** SS treats it as schema v1 and defaults v2-only fields to null/empty values

#### Draft preview output schema (v2)

```json
{
  "schema_version": 2,
  "draft_text": "string",
  "outcome_var": "string|null",
  "treatment_var": "string|null",
  "controls": ["string", "..."],
  "time_var": "string|null",
  "entity_var": "string|null",
  "cluster_var": "string|null",
  "fixed_effects": ["string", "..."],
  "interaction_terms": ["string", "..."],
  "instrument_var": "string|null",
  "analysis_hints": ["string", "..."],
  "default_overrides": {}
}
```

### Requirement: LLMPlan is frozen and replayable

`LLMPlan` MUST be a structured execution plan and MUST be persisted both:
- in `job.json` under `llm_plan`
- as an artifact `artifacts/plan.json` (kind: `plan.json`) and indexed in `artifacts_index`

`LLMPlan` v1 MUST include:
- `plan_version` (int, `1`)
- `plan_id` (string; deterministic fingerprint)
- `rel_path` (string; job-relative artifact path)
- `plan_source` (string enum: `llm`, `rule`, `rule_fallback`; default: `rule`)
- `fallback_reason` (string | null; present when `plan_source=rule_fallback`)
- `steps[]` where each step has:
  - `step_id` (string)
  - `type` (enum)
  - `purpose` (string)
  - `params` (object)
  - `depends_on[]` (string list)
  - `fallback_step_id` (string | null)
  - `produces[]` (artifact kind enums; aligned with `ss-job-contract`)

#### Scenario: Plan freeze is idempotent
- **WHEN** `PlanService.freeze_plan()` is called repeatedly with the same inputs
- **THEN** it returns the same plan and does not duplicate artifact index entries

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
