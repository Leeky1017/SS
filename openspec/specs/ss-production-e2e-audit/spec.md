# Spec: ss-production-e2e-audit

## Purpose

Define a production-grade end-to-end (E2E) audit checklist for SS, including acceptance criteria, evidence requirements, and pass/fail judgement rules for go/no-go decisions.

## Requirements

### Requirement: The audit spec pack exists and is executable

The audit spec pack MUST exist under `openspec/specs/ss-production-e2e-audit/` and MUST provide task cards that operators can execute to produce auditable evidence.

#### Scenario: Spec pack is present
- **WHEN** browsing `openspec/specs/ss-production-e2e-audit/`
- **THEN** `spec.md` and `task_cards/` exist

### Requirement: Production chains are explicitly inventoried (wired vs present)

An audit run MUST explicitly document which runtime chains are wired for production execution and which are merely present in the repository:
- versioned API chain: `/v1/**`
- any non-versioned HTTP chain (non-`/v1`)
- do-template library chain (template assets + index + selection + rendering + runner execution)

The inventory MUST separate:
- connected surfaces (reachable through the running API/worker)
- disconnected components (exist on disk but not reachable or not invoked in the production journey)

#### Scenario: Inventory includes versioned and unversioned surfaces
- **WHEN** reviewing the inventory notes for an audit run
- **THEN** it lists `/v1` routes and any non-`/v1` routes with evidence (route definitions + runtime reachability)

#### Scenario: Do-template library chain is classified as wired or not
- **WHEN** reviewing the inventory notes for an audit run
- **THEN** it states whether templates in `assets/stata_do_library/**` are loaded and executed by the production runner, and where the integration boundary is

### Requirement: E2E audit uses real dependencies (no stub LLM, no fake runner)

An audit run MUST start SS in a production-like way (API + worker) and MUST use:
- a real Stata runner (not a fake runner)
- a real (non-stub) LLM provider with `SS_LLM_MODEL=claude-opus-4-5-20251101`

The audit evidence MUST include:
- process start commands (API and worker)
- a log line (or persisted run meta) that identifies the runner implementation and the executed Stata command
- evidence that LLM calls were made by a non-stub provider (request/response metadata saved as artifacts)

#### Scenario: Real Stata runner is evidenced
- **WHEN** the E2E audit reaches a terminal job state
- **THEN** the job’s artifacts include a Stata log (`stata.log`) and run metadata that includes the executed Stata command and exit code

#### Scenario: Real LLM provider is evidenced with the forced model
- **WHEN** the E2E audit produces a draft preview
- **THEN** the job artifacts include LLM metadata showing the model name `claude-opus-4-5-20251101` (stub provider uses `model=stub`)

### Requirement: The `/v1` production journey is executable end-to-end with recoverable artifacts

An audit run MUST execute the following HTTP journey against a running SS API and worker:
- redeem: `POST /v1/task-codes/redeem` → returns `job_id` + bearer token
- upload: `POST /v1/jobs/{job_id}/inputs/upload` (CSV)
- inputs preview: `GET /v1/jobs/{job_id}/inputs/preview`
- draft preview: `GET /v1/jobs/{job_id}/draft/preview`
- freeze plan: `POST /v1/jobs/{job_id}/plan/freeze`
- run: `POST /v1/jobs/{job_id}/run` and poll job status until terminal
- artifacts: `GET /v1/jobs/{job_id}/artifacts` and download at least one produced artifact

The audit MUST also restart the API/worker and demonstrate that:
- job status is recoverable after restart
- artifacts remain indexable and downloadable after restart

#### Scenario: Redeem returns a usable job token
- **WHEN** calling `POST /v1/task-codes/redeem` with a valid `task_code`
- **THEN** the response includes `job_id` and a bearer token usable for subsequent authenticated calls

#### Scenario: Plan freeze includes template choice, bindings, dependencies, and artifact contract
- **WHEN** calling `POST /v1/jobs/{job_id}/plan/freeze`
- **THEN** the frozen plan includes:
  - the selected template identifier (or equivalent template reference) and selection rationale
  - bound parameters (including explicit missing/unknown fields)
  - dependency information (ado/SSC packages or equivalent)
  - an artifacts contract or index schema describing expected outputs and their storage locations

#### Scenario: Artifacts are contract-indexed and survive restart
- **WHEN** calling `GET /v1/jobs/{job_id}/artifacts` after a successful run and after a restart
- **THEN** the response provides an index of artifacts that can be downloaded, and the downloaded files match the declared contract

### Requirement: Key audit points have pass/fail judgement rules

An audit run MUST produce a pass/fail conclusion for each of the following points, backed by evidence:
- template selection stability (not hard-coded)
- parameter binding correctness (and structured error on missing inputs)
- ado/SSC dependency handling (detectable failure + recoverable retry path)
- artifact contract archiving and indexable downloadability

#### Scenario: Template selection is not hard-coded
- **WHEN** comparing the plan freeze output with the template selection implementation evidence
- **THEN** the selected template is justified by inputs/LLM output and the selection mechanism is not a constant hard-coded template id

#### Scenario: Missing parameters yield structured errors
- **WHEN** a required parameter is missing at plan freeze or run time
- **THEN** SS responds with a structured error (event code + context) that is diagnosable and can be retried after correction

#### Scenario: Missing ado/SSC dependency is diagnosable and recoverable
- **WHEN** Stata execution fails due to a missing ado/SSC dependency
- **THEN** the failure is reported with a dependency identifier and the job can be retried after installing or resolving the dependency

