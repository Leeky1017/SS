# Phase 3: Template Composition (Pipeline) MVP

## Metadata

- Issue: TBD
- Parent: #125
- Related specs:
  - `openspec/specs/ss-do-template-optimization/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`

## Goal

Support multi-template analysis as an explicit ordered pipeline with auditable wiring, without building a general workflow engine.

## In scope

- Define a minimal pipeline schema (ordered steps, explicit input/output bindings).
- Add “primary dataset output” semantics to template metadata (or a derived registry) to enable dataset chaining.
- Implement pipeline execution:
  - per-step run directories
  - explicit copy/link of selected dataset output into next-step input location
  - per-step artifacts + a pipeline-level summary artifact describing the wiring

## Out of scope

- DAG execution, branching, retries across steps.
- Automatic inference of wiring without explicit bindings.

## Acceptance checklist

- [ ] Pipeline schema exists and is validated (schema + tests)
- [ ] Pipeline execution archives per-step evidence + a pipeline wiring summary
- [ ] Dataset chaining works end-to-end on at least 2 representative templates
- [ ] No implicit state transfer: all wiring is explicit and recorded

