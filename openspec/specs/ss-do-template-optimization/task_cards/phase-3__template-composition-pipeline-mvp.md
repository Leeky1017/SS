# Phase 3: Template Composition (Adaptive Multi-Data) MVP

## Metadata

- Issue: #151
- Parent: #125
- Related specs:
  - `openspec/specs/ss-do-template-optimization/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Goal

Support multi-template analysis over 1+ input datasets using an explicit, auditable composition plan that is **adaptive**
(LLM chooses a minimal composition mode based on inputs and the requirement), without building a general workflow engine.

## In scope

- Multi-file inputs:
  - Support 2+ uploaded dataset files (job inputs manifest + artifact indexing).
  - Introduce dataset roles: `primary_dataset` / `secondary_dataset` / `auxiliary_data`.
- Adaptive composition modes (explicitly declared in the plan; small closed set):
  - **Sequential**: simple ordered steps on one dataset (baseline).
  - **Merge-then-sequential**: merge/append datasets first, then run the analysis pipeline.
  - **Parallel-then-aggregate**: run per-dataset analyses in isolated runs, then aggregate results.
  - **Conditional**: choose next step based on an explicit predicate over prior step outputs.
- Plan/schema enhancements:
  - Explicit data-flow declarations (which dataset feeds which step input role).
  - Explicit intermediate products (which step produces which dataset/output artifacts).
- Execution support (still minimal, but correct for the supported modes):
  - Resolve data dependencies and execute in the correct order.
  - Per-step run directories + archived artifacts.
  - Pipeline-level summary artifact describing data-flow + wiring + mode decisions.

## Out of scope

- Arbitrary DAG/workflow engine (general fan-out/fan-in graphs, loops, dynamic step generation).
- “Hidden” inference: executor MUST NOT guess wiring; plan must be explicit.
- Distributed scheduling for parallelism (parallel mode may be executed sequentially but isolated).

## Acceptance checklist

- [ ] Multiple dataset inputs are supported (>= 2) with explicit roles and an inputs manifest
- [ ] Composition plan schema exists and is validated (schema + tests), including mode + data-flow declarations
- [ ] Executor correctly handles data dependencies and produces per-step evidence + pipeline summary artifacts
- [ ] Simple single-file jobs remain minimal (Sequential mode; no merge/parallel/conditional scaffolding)
- [ ] End-to-end coverage includes at least:
  - 1 merge-then-sequential scenario, and
  - 1 parallel-then-aggregate scenario
- [ ] No implicit state transfer: all wiring is explicit and recorded

## Recommended breakdown (to keep increments small)

- Phase 3.1: multi-dataset inputs + roles (`phase-3.1__multi-dataset-inputs-and-roles.md`)
- Phase 3.2: composition plan schema + routing rules (`phase-3.2__composition-plan-schema-and-routing.md`)
- Phase 3.3: executor modes + evidence (`phase-3.3__composition-executor-modes-and-evidence.md`)
