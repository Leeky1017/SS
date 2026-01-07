# Spec: ss-do-template-optimization

## Purpose

Define a maintainable optimization strategy for the Stata do-template library (`assets/stata_do_library/`) so SS can:

- reliably validate + load templates,
- help the LLM efficiently select the right template(s),
- support explicit multi-template composition (pipelines),
- and keep the library internally consistent (no drift between do/meta/index/docs).

## Scope

In scope:
- Taxonomy + metadata standardization (single source of truth)
- Index design for LLM retrieval (token-budgeted)
- Duplicate/merge/delete strategy (no redundant templates kept “just in case”)
- Composition contract (minimal pipeline, explicit file passing)
- Quality gates and evidence requirements

Out of scope (tracked via task cards):
- Bulk rewriting of 319 templates in this round
- Backward compatibility guarantees for old IDs/structures (optimize forward)

## Requirements

### Requirement: Canonical metadata is schema-validated and index-driven

SS MUST treat per-template `meta.json` as the canonical record and MUST generate any index/view files from it (no hand-edited duplicated truth).

#### Scenario: Index and meta cannot drift
- **GIVEN** a template set (`do/*.do` + `do/meta/*.meta.json`)
- **WHEN** generating runtime indices
- **THEN** the generated indices are internally consistent (counts, status summaries, id lists)
- **AND** CI fails on any mismatch

### Requirement: Taxonomy is canonical, de-duplicated, and LLM-friendly

The library MUST define a canonical taxonomy that avoids ambiguous duplicates (e.g., `panel` vs `panel_data`) and provides aliases/keywords for retrieval.

#### Scenario: Family selection uses canonical IDs
- **GIVEN** a request that matches an alias family label
- **WHEN** selecting candidate families/templates
- **THEN** SS resolves to canonical family IDs
- **AND** records the resolution in run artifacts for audit

### Requirement: Placeholder names are standardized and validated

Templates MUST use a canonical placeholder naming scheme, and SS MUST fail fast on missing required parameters.

#### Scenario: Placeholder variants are normalized
- **GIVEN** a library that historically used placeholder variants (e.g. `__TIME_VAR__` vs `__TIMEVAR__`)
- **WHEN** running template rendering
- **THEN** SS either (a) enforces the canonical placeholder set, or (b) normalizes variants before rendering
- **AND** the normalization rule is deterministic and test-covered

### Requirement: Output semantics support archiving and composition

Template outputs MUST be declared in metadata with stable types, and MUST support “primary dataset output” semantics for pipeline composition.

#### Scenario: Outputs are archived and safe
- **WHEN** a template run completes
- **THEN** SS archives declared outputs into artifacts
- **AND** rejects any output path that escapes the run workspace (no `..`, no absolute paths)

#### Scenario: Primary dataset output is composable
- **GIVEN** a template that produces a dataset for downstream steps
- **WHEN** composing multiple templates in a pipeline
- **THEN** SS can deterministically select the intended dataset output for the next step

### Requirement: LLM retrieval index is token-budgeted and selection is verifiable

SS MUST provide an LLM-facing retrieval index that supports budgeted prompts and a verifiable selection protocol.

#### Scenario: Two-stage selection is enforced
- **WHEN** selecting from 300+ templates
- **THEN** SS performs:
  1) family (or capability-group) selection from summaries, then
  2) template selection from a trimmed candidate set
- **AND** the chosen `template_id` MUST be a member of the candidate set (otherwise structured failure)

### Requirement: Template composition is explicit and minimal (no hidden workflow engine)

If SS supports multi-template runs, it MUST do so as an explicit ordered pipeline with explicit input/output wiring (no implicit state transfer).

#### Scenario: Pipeline execution is auditable
- **GIVEN** a pipeline with N template steps
- **WHEN** executing the pipeline
- **THEN** SS archives per-step template source/meta/params/logs/outputs
- **AND** records the wiring decisions (which output fed which next-step input)

### Requirement: Quality gates produce reproducible evidence

SS MUST provide:
- strict static validation (schema + lint + index consistency) in CI, and
- a runnable Stata 18 smoke-suite (may be non-CI if licensing blocks) with reproducible run logs.

#### Scenario: Quality gates block regressions
- **WHEN** a template violates schema/contract/index invariants
- **THEN** CI fails with a structured error report referencing the offending template ID(s)

