# Phase 3.3: Composition Executor (Modes + Evidence)

## Metadata

- Issue: TBD
- Parent: #125
- Superphase: Phase 3 (adaptive composition)
- Depends on:
  - Phase 3.1 (multi-dataset inputs)
  - Phase 3.2 (composition plan schema)
- Related specs:
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-do-template-optimization/COMPOSITION_ARCHITECTURE.md`

## Goal

Execute a composition plan with correct data-flow handling and a complete evidence trail for the supported modes:
sequential / merge-then-sequential / parallel-then-aggregate / conditional.

## In scope

- Parse plan dependencies and compute a valid execution order.
- Resolve `dataset_ref` bindings and materialize inputs into each step run workspace explicitly.
- Execute steps (template runs) via Stata runner isolation, capturing outputs as artifacts.
- Support mode-specific behavior:
  - merge/append step produces a merged dataset product for downstream steps
  - parallel branches run in isolated step runs; aggregation consumes declared products
  - conditional branches execute based on an explicit predicate and record the decision
- Evidence:
  - per-step run dirs with inputs + do/log + outputs
  - pipeline-level `composition_summary.json` with resolved bindings + produced products + decisions

## Out of scope

- Distributed parallel scheduling (logical parallel only).
- Arbitrary DAG features (loops, dynamic fan-out, retries across steps).

## Acceptance checklist

- [ ] Executor validates plans and rejects unknown dataset refs / ambiguous products
- [ ] Each supported composition mode has at least one end-to-end test scenario
- [ ] Per-step evidence is archived and indexed
- [ ] Pipeline-level summary artifact records bindings, products, and decisions (merge/aggregate/branch)
- [ ] Simple sequential jobs remain minimal and auditable
