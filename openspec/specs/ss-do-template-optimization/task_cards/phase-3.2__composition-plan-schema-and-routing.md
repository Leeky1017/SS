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

- [ ] Plan schema exists and is validated (schema + tests)
- [ ] Planner selects one of the supported composition modes and records it in the plan
- [ ] Plan includes explicit data-flow bindings and intermediate product declarations
- [ ] Simple single-file jobs produce a sequential plan without unnecessary scaffolding
- [ ] Fixtures/examples cover merge-then-sequential and parallel-then-aggregate
