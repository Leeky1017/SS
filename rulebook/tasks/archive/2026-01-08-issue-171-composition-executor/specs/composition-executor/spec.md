---
title: Composition Executor (modes + evidence)
issue: 171
---

# Spec: composition-executor (Phase 3.3)

## Requirements

### Requirement: Executor validates and orders the plan

The executor MUST:
- validate that `dataset_ref` values resolve to either `input:<dataset_key>` or `prod:<step_id>:<product_id>`,
- reject unknown input keys or unknown product refs,
- and compute a valid execution order from `depends_on` (reject cycles).

#### Scenario: Unknown dataset_ref is rejected
- **GIVEN** a plan referencing `input:unknown`
- **WHEN** the worker executes the plan
- **THEN** the run fails with error code `PLAN_COMPOSITION_INVALID`

### Requirement: Executor materializes step inputs explicitly

For each step, the executor MUST:
- create a step run directory,
- write an `inputs/` evidence directory for the step,
- materialize bound inputs into that directory deterministically,
- and run the step in an isolated workspace.

#### Scenario: Step inputs are materialized into the step run directory
- **GIVEN** a multi-step plan with `input_bindings`
- **WHEN** the worker executes the plan
- **THEN** each executed step has `runs/<step_run_id>/inputs/manifest.json`

### Requirement: Mode-specific behavior is recorded and auditable

The executor MUST support the following modes and record decisions:
- `merge_then_sequential`: produce a merged dataset product for downstream steps
- `parallel_then_aggregate`: run independent steps in isolated runs, then aggregate using declared products
- `conditional`: evaluate an explicit predicate and execute exactly one branch

#### Scenario: Conditional chooses a single branch and records decision
- **GIVEN** a conditional plan with an explicit predicate
- **WHEN** the worker executes the plan
- **THEN** only the selected branch steps run and `composition_summary.json` records the branch decision

### Requirement: Evidence is written at step and pipeline levels

The executor MUST write:
- per-step evidence directories under `runs/<step_run_id>/` (including `inputs/`, `work/`, and `artifacts/`),
- and a pipeline-level `composition_summary.json` under `runs/<pipeline_run_id>/artifacts/`.

