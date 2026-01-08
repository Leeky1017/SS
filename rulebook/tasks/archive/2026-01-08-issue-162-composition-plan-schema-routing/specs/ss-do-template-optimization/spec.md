# Spec Delta: Composition Plan Schema + Routing (Issue #162)

## Purpose

Define a composition-aware, schema-validatable plan encoding (LLMPlan v1-compatible via reserved `params` keys) and planner routing rules so:
- simple single-file jobs remain `sequential` and minimal, and
- multi-dataset requirements can be expressed explicitly (bindings + declared products) without implicit wiring.

## Requirements

### Requirement: Plan encodes a closed-set `composition_mode`

The plan MUST specify `composition_mode` as one of:
- `sequential`
- `merge_then_sequential`
- `parallel_then_aggregate`
- `conditional`

The value MUST be consistent across all steps.

#### Scenario: Mode mismatch is rejected
- **GIVEN** a plan where steps declare different `composition_mode` values
- **WHEN** a plan contains steps with different `composition_mode` values
- **THEN** plan validation fails with a structured error.

### Requirement: Plan uses explicit dataset bindings and product declarations

Template steps MUST declare:
- `input_bindings` mapping input role → `dataset_ref`, and
- `products` as a list of declared outputs with stable `product_id` values.

`dataset_ref` MUST follow the grammar:
- `input:<dataset_key>`
- `prod:<step_id>:<product_id>`

#### Scenario: Unknown dataset ref is rejected
- **GIVEN** a plan with `input_bindings` that reference `dataset_ref` values
- **WHEN** an `input_bindings` entry references an unknown input dataset key or a missing product
- **THEN** plan validation fails with a structured error.

#### Scenario: Ambiguous product identifiers are rejected
- **GIVEN** a step that declares intermediate `products`
- **WHEN** a step declares duplicate `product_id` values
- **THEN** plan validation fails with a structured error.

### Requirement: Planner chooses the simplest sufficient mode

The planner MUST select the simplest `composition_mode` that satisfies the job inputs and requirement.

#### Scenario: Single-file job defaults to sequential
- **GIVEN** a job with a single dataset input
- **WHEN** planning a minimal analysis pipeline
- **THEN** the plan uses `composition_mode = sequential` and does not add unnecessary scaffolding.
