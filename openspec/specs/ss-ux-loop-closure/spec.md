# Spec: ss-ux-loop-closure

## Purpose

Define the production-readiness UX-loop requirements for SS and provide a single authoritative home for the current UX blockers and their task cards.

This spec is **user-centric**: it answers “can a real user complete one full empirical analysis and download usable result files?” and turns the gaps into actionable, testable requirements.

## Background

SS currently passes many architecture and safety constraints, but the production-readiness UX audit concludes that the **minimum UX loop is not yet runnable** via the public HTTP API + default worker configuration.

Audit report (evidence): `Audit/04_Production_Readiness_UX_Audit.md`

High-level blockers identified by the audit:
- Missing **dataset input** (upload + preview)
- Missing **plan freeze/preview** in the user path (worker needs `job.llm_plan`)
- Worker execution path not wired to **DoFileGenerator + configurable StataRunner**, so it does not produce user-meaningful outputs

## Related specs (normative)

- API surface and versioning: `openspec/specs/ss-api-surface/spec.md`
- Job contract + artifacts: `openspec/specs/ss-job-contract/spec.md`
- LLM brain (plans + LLM artifacts): `openspec/specs/ss-llm-brain/spec.md`
- State machine + idempotency: `openspec/specs/ss-state-machine/spec.md`
- Stata runner contract: `openspec/specs/ss-stata-runner/spec.md`
- User-centric testing strategy: `openspec/specs/ss-testing-strategy/README.md`

## UX loop definition (v1)

The “UX loop” is the minimal user journey that MUST be possible using only:
- SS HTTP API (no direct service calls)
- SS worker process (no test-only injection)

Phases (v1):
1) Input (dataset upload + preview)
2) Understand (draft + plan generation / preview)
3) Confirm (user confirms to proceed)
4) Execute (queued → running → finished with evidence)
5) Output (artifacts index + download usable result files)
6) Recoverability (reload/resume, idempotent retries, clear failures)

## Minimum user journey (A) to be supported

This spec defines a minimum “Journey A” compatible with the testing strategy:
1) Create a job with a natural-language requirement
2) Upload a primary dataset for that job and preview it
3) Preview draft (LLM stub/prod), then preview/freeze an execution plan
4) Confirm and enqueue execution
5) Poll job status until finished
6) List artifacts and download at least one “result” file plus logs

## Requirements

### Requirement: Minimum UX loop MUST be achievable end-to-end

SS MUST allow a real user to complete the minimum Journey A end-to-end using only HTTP API calls plus a worker consuming the queue.

#### Scenario: Journey A completes and yields downloadable results
- **GIVEN** a user starts with a dataset file and a natural-language requirement
- **WHEN** the user completes create → upload/preview → draft/plan preview → confirm → poll → artifacts download
- **THEN** the job reaches `succeeded`
- **AND** the artifacts index includes at least one user-meaningful result file (table) and run evidence (log + meta)

### Requirement: Inputs MUST be uploadable and previewable

SS MUST provide an API-supported way to attach a “primary dataset” to a job, persist it under the job workspace `inputs/`, and provide a small preview for column recognition and sanity checks.

Inputs MUST be stored with job-relative safe paths and MUST NOT allow traversal or symlink escape.

#### Scenario: Uploading a dataset persists inputs and updates job.json
- **GIVEN** an existing job
- **WHEN** the user uploads a dataset file (CSV/Excel/DTA)
- **THEN** the dataset is persisted under `inputs/` in the job workspace
- **AND** `job.json` updates `inputs.manifest_rel_path` and `inputs.fingerprint`

#### Scenario: Preview shows columns and sample rows
- **GIVEN** a job with an uploaded primary dataset
- **WHEN** the user requests a preview
- **THEN** the response includes column names and a small sample of rows

#### Scenario: Bad inputs fail with clear structured errors
- **GIVEN** an empty file or an unsupported/invalid format
- **WHEN** the user uploads or previews the dataset
- **THEN** SS responds with a structured error (stable `error_code`, human-readable `message`)

### Requirement: User-visible messages MUST NOT expose internal technical terms

User-visible messages (UI copy, alerts, and displayed errors) MUST avoid internal implementation terminology, including:
- AI/ML terms (AI, LLM, prompt, token, embedding, inference)
- frontend/backend terms (API, JSON, HTTP, request/response, frontend, backend)
- internal system fields (draft, payload, schema, contract, job_id, tenant)
- programming terms (null, undefined, stack trace, exception)
- storage terms (database, query, cache, store, persist)

#### Scenario: UI copy is implementation-agnostic
- **WHEN** a user completes Journey A using the shipped frontend
- **THEN** the UI does not render any of the internal technical terms above

### Requirement: User-visible errors MUST be numeric-coded with friendly text

User-visible errors MUST be shown as numeric codes plus a friendly hint in this format:
- `错误代号 EXXXX：<friendly description>`

User-visible errors MUST NOT directly display raw backend `message`/`detail`, stack traces, or internal `error_code` values.

#### Scenario: A backend failure is shown as a numeric code
- **GIVEN** an API call fails with a structured SS error (e.g., `error_code="LLM_CALL_FAILED"`)
- **WHEN** the frontend renders the failure
- **THEN** it shows a numeric-code message (e.g., `错误代号 E4001：...`)
- **AND** it does not display the raw backend `message`/`detail` or internal `error_code`

### Requirement: Plan MUST be frozen before queueing and MUST be previewable

SS MUST ensure a job has a frozen `LLMPlan` before it transitions to `queued`, because worker execution depends on `job.llm_plan`.

The frozen plan MUST be persisted:
- inside `job.json` (`llm_plan`)
- as an artifact `artifacts/plan.json` (kind: `plan.json`) indexed in `artifacts_index`

#### Scenario: Confirm enforces plan availability
- **GIVEN** a job in `draft_ready`
- **WHEN** the user confirms execution
- **THEN** SS freezes the plan (or requires an explicit plan-freeze step) before enqueueing
- **AND** the job transitions to `queued` without leaving `llm_plan` unset

#### Scenario: Users can preview the plan
- **GIVEN** a job with a frozen plan
- **WHEN** the user requests plan preview
- **THEN** the plan is visible via API (direct endpoint or artifacts download)

### Requirement: Worker MUST execute plan using DoFileGenerator + configurable runner

The worker MUST execute queued jobs by:
1) Loading the job and required inputs manifest
2) Generating a do-file via `DoFileGenerator` from the frozen `LLMPlan` and inputs manifest
3) Executing via a configurable `StataRunner` (fake in tests/dev; local runner in production)
4) Persisting evidence artifacts and updating job status

#### Scenario: Worker execution produces run evidence artifacts
- **GIVEN** a job in `queued` with `llm_plan` and inputs manifest available
- **WHEN** a worker claims and executes the job
- **THEN** the job transitions through `running` and ends in `succeeded` or `failed`
- **AND** artifacts include do-file + logs + run meta

### Requirement: Outputs MUST include at least one result artifact

For successful runs, SS MUST produce at least one user-meaningful “result” artifact (e.g., an exported table) in addition to logs, and make it downloadable via the artifacts API.

#### Scenario: Success includes a result table file
- **GIVEN** a job run succeeds
- **WHEN** listing artifacts
- **THEN** the index includes an export-table artifact (kind aligned with `ss-job-contract`)
- **AND** the file is downloadable through the artifacts download endpoint

## Blockers and task cards

Current blockers (P0) live under this spec’s task cards:
- UX-B001: dataset upload + preview
- UX-B002: plan freeze + plan preview in user path
- UX-B003: worker execution wiring (DoFileGenerator + configurable runner + result artifacts)

See: `openspec/specs/ss-ux-loop-closure/task_cards/`
