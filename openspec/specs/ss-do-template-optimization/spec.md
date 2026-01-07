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

### Requirement: Stage-1 selects canonical family IDs (schema-bound)

SS MUST run a stage-1 family selection step that returns canonical family IDs from `FamilySummary[]` for the user requirement.

Stage-1 input:
- user requirement text, and
- `FamilySummary[]` (canonical family IDs + short summaries).

Stage-1 output MUST be schema-bound JSON and MUST include:
- `families[]` where each item includes:
  - `family_id` (canonical)
  - `reason`
  - `confidence` (0.0–1.0)

Stage-1 MUST hard-validate that every returned family ID is a member of the provided canonical family ID set; otherwise it MUST retry/fail in a bounded, structured way.

#### Scenario: Stage-1 output uses canonical family IDs
- **GIVEN** a `FamilySummary[]` list with canonical IDs
- **WHEN** the LLM returns a stage-1 selection output
- **THEN** every selected ID is in the canonical ID set
- **AND** the output includes reasons + confidences per selected family

### Requirement: Stage-2 selects a template from a token-budgeted candidate set (schema-bound)

SS MUST run a stage-2 template selection step that selects a `template_id` from a token-budgeted, trimmed candidate set built from the stage-1 selected families.

Stage-2 input:
- user requirement text, and
- candidate families → load `TemplateSummary[]` for those families.

Stage-2 preparation MUST:
- rank templates, then
- deterministically trim to a topK candidate set within a configured token budget.

Stage-2 output MUST be schema-bound JSON and MUST include:
- `template_id`
- `reason` and `confidence` (0.0–1.0)

Stage-2 MUST hard-validate `template_id ∈ candidate_template_ids`; otherwise it MUST retry/fail in a bounded, structured way.

#### Scenario: Stage-2 rejects out-of-candidate template IDs
- **GIVEN** a trimmed candidate set of template IDs
- **WHEN** the LLM returns a `template_id` not in the candidate set
- **THEN** SS retries (bounded) or fails with a structured error
- **AND** it does not proceed with an unverified template ID

### Requirement: Selection writes evidence artifacts (auditable + verifiable)

Template selection MUST write evidence artifacts that capture:
- stage-1 provided family set + chosen families (with reasons + confidence),
- stage-2 candidate template set (post-trim) + final selection (with reasons + confidence).

The evidence artifacts MUST be indexed as job artifacts and MUST use enumerated `do_template.*` kinds.

#### Scenario: Selection evidence is persisted and indexed
- **WHEN** template selection runs for a job
- **THEN** evidence artifacts exist on disk under the job workspace
- **AND** the job `artifacts_index` contains refs for the selection artifacts

### Requirement: Template composition is explicit and minimal (no hidden workflow engine)

If SS supports multi-template runs, it MUST do so as an explicit composition plan with explicit input/output wiring and dataset roles (no implicit state transfer).
The composition mechanism MUST remain minimal and MUST only support a small closed set of modes (see `COMPOSITION_ARCHITECTURE.md`):
- sequential
- merge-then-sequential
- parallel-then-aggregate
- conditional

#### Scenario: Pipeline execution is auditable
- **GIVEN** a composition plan with N steps and explicit data-flow bindings
- **WHEN** executing the pipeline
- **THEN** SS archives per-step template source/meta/params/logs/outputs
- **AND** records the wiring decisions (datasets/outputs feeding downstream inputs, plus merge/aggregate/branch decisions)

### Requirement: Quality gates produce reproducible evidence

SS MUST provide:
- strict static validation (schema + lint + index consistency) in CI, and
- a runnable Stata 18 smoke-suite (may be non-CI if licensing blocks) with reproducible run logs.

#### Scenario: Quality gates block regressions
- **WHEN** a template violates schema/contract/index invariants
- **THEN** CI fails with a structured error report referencing the offending template ID(s)
