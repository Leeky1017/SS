# Spec delta: ss-llm-brain (ISSUE-450)

## Scope
- Draft preview LLM output schema v2: capture panel identifiers, clustering, fixed effects, interaction terms (e.g., DID), and IV instruments.
- Parsing: v2 parsing with v1 JSON fallback; parse failures are explicit errors for schema-bound outputs.

## Requirements

### R1: Draft preview output schema is versioned (v2)
- Draft preview LLM MUST return a JSON object with `schema_version=2` and the fields listed in "Schema (v2)".

#### Scenario: v2 output includes advanced econometrics fields
- **GIVEN** a user requirement and a list of column candidates
- **WHEN** draft preview is asked to extract variables for panel / DID / IV requirements
- **THEN** it outputs `time_var`, `entity_var`, `cluster_var`, `fixed_effects[]`, `interaction_terms[]`, `instrument_var`, and `analysis_hints[]` in addition to v1 fields.

### R2: Parser accepts v1 JSON as fallback

#### Scenario: v1 output remains supported
- **GIVEN** a v1 JSON draft preview output (without `schema_version`)
- **WHEN** draft preview returns a v1 JSON object without `schema_version`
- **THEN** parsing treats it as schema v1 and defaults v2-only fields to null/empty values.

### R3: Parse failures are not silent

#### Scenario: invalid JSON triggers a parse failure
- **GIVEN** a draft preview response text that is not valid JSON
- **WHEN** draft preview response is not valid JSON (or violates the schema)
- **THEN** parsing raises a specific error and the caller can treat it as an error path.

## Schema (v2)

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
