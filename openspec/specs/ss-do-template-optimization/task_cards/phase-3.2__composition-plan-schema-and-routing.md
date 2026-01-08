# Phase 3.2: Composition Plan Schema + Routing

## Metadata

- Issue: #162
- Parent: #125
- Superphase: Phase 3 (adaptive composition)
- Related specs:
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`
  - `openspec/specs/ss-do-template-optimization/COMPOSITION_ARCHITECTURE.md`

## Goal

Define a **composition-aware, schema-bound** plan that:
- selects a composition mode from a small closed set,
- declares explicit data-flow bindings (dataset → step input roles),
- and declares intermediate products for downstream wiring.

The plan MUST keep simple single-file jobs **simple** (sequential, minimal steps).

## In scope

- Plan schema conventions (LLMPlan v1-compatible via reserved `params` keys) covering:
  - `composition_mode` enum
  - `dataset_ref` grammar (`input:<dataset_key>` / `prod:<step_id>:<product_id>`)
  - `input_bindings` and `products` declarations
- Validation + tests for:
  - unknown dataset refs
  - missing/ambiguous product identifiers
  - inconsistent `composition_mode`
- Planner behavior:
  - choose among `sequential` / `merge_then_sequential` / `parallel_then_aggregate` / `conditional`
  - prefer the simplest mode that satisfies the requirement and available inputs
- Examples/fixtures for at least:
  - 2-file merge-then-sequential plan
  - 2-file parallel-then-aggregate plan

## Out of scope

- Executing the plan (Phase 3.3).
- Automatic wiring without explicit plan bindings.

## Acceptance checklist

- [x] Plan schema exists and is validated (schema + tests)
- [x] Planner selects one of the supported composition modes and records it in the plan
- [x] Plan includes explicit data-flow bindings and intermediate product declarations
- [x] Simple single-file jobs produce a sequential plan without unnecessary scaffolding
- [x] Fixtures/examples cover merge-then-sequential and parallel-then-aggregate

## Completion

- PR: https://github.com/Leeky1017/SS/pull/167
- Added composition-aware plan schema validation (`composition_mode`, `dataset_ref`, `input_bindings`, `products`) with error handling.
- Routed planner to choose the simplest supported `composition_mode` and kept single-file jobs minimal.
- Added fixtures/examples for merge-then-sequential and parallel-then-aggregate plans.
- Run log: `openspec/_ops/task_runs/ISSUE-162.md`
