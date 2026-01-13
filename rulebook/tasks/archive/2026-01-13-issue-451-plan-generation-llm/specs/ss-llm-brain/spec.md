# Spec delta: ss-llm-brain (ISSUE-451)

## Scope
- Add an LLM-backed plan generation operation to map requirement → multi-step execution plan.
- Extend plan schema with `plan_source`, richer step metadata, and additional semantic step types.
- Add explicit fallback-to-rule behavior when LLM output is invalid/unsupported, with evidence recorded.

## Requirements

### R1: Plan generation prompt is schema-bound

#### Scenario: LLM plan generation returns JSON
- **GIVEN** a job requirement, draft context, selected templates, and constraints (e.g., max_steps)
- **WHEN** SS asks the LLM to generate a plan
- **THEN** the LLM returns ONLY a JSON object that matches the plan schema.

### R2: LLM plan parsing failures fall back to rule plan (no silent failure)

#### Scenario: invalid JSON triggers rule fallback
- **GIVEN** a plan generation response that is not valid JSON
- **WHEN** SS parses the response
- **THEN** it falls back to the existing rule-based plan and records a structured fallback reason.

#### Scenario: schema validation failure triggers rule fallback
- **GIVEN** a plan generation response that is valid JSON but violates the schema
- **WHEN** SS validates the parsed plan
- **THEN** it falls back to the existing rule-based plan and records a structured fallback reason.

#### Scenario: unsupported step types trigger rule fallback
- **GIVEN** a plan generation response that contains an unknown/unsupported step type
- **WHEN** SS parses/validates the plan
- **THEN** it falls back to the existing rule-based plan and records a structured fallback reason.

### R3: Plan artifacts record the plan source

#### Scenario: plan source is explicit
- **GIVEN** SS has produced a plan for a job
- **WHEN** a plan is persisted as `artifacts/plan.json`
- **THEN** it includes `plan_source` as `llm`, `rule`, or `rule_fallback`.
