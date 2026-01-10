# Spec: ss-production-e2e-audit-remediation

## Purpose

Remediate **all** issues evidenced by the production E2E audit (`openspec/specs/ss-production-e2e-audit/`, run log `openspec/_ops/task_runs/ISSUE-274.md`) and converge SS to a **single authoritative production execution chain**:

- `/v1` redeem → inputs → draft preview → plan freeze → run → artifacts (survive restart)
- real Stata runner (no fake runner)
- real LLM provider (no stub provider)
- real do-template library chain (assets → index → selection → rendering → runner execution)

Non-production chains and “fallback” code paths (hard-coded template ids, stub/fake providers, legacy business endpoints) MUST be removed, not merely hidden.

## Requirements

### Requirement: Only `/v1/**` is the authoritative business HTTP surface

SS MUST NOT expose any non-`/v1` business endpoints (jobs/draft/bundle/upload-session operations). If an operational surface exists (health/metrics), it MUST NOT provide alternate business execution paths.

#### Scenario: Legacy business endpoints are not reachable
- **WHEN** starting SS in production mode
- **THEN** requests to non-`/v1` business paths (e.g., `/jobs/**`) are not routable

### Requirement: Do-template library is wired into `/v1` plan and run

SS MUST select and execute a real do-template from `assets/stata_do_library/**` in the `/v1` journey and MUST NOT hard-code a constant `template_id`.

#### Scenario: Plan freeze references a real template
- **WHEN** calling `POST /v1/jobs/{job_id}/plan/freeze`
- **THEN** the returned plan references a real `template_id` from the library index (not `stub_descriptive_v1`)

### Requirement: Plan freeze returns an explicit execution contract

Plan freeze MUST return a plan that explicitly includes:
- parameter binding contract (required/optional + bound values + missing list)
- dependency declarations (ado/SSC/built-in)
- outputs/artifacts contract (declared outputs + archive constraints)

#### Scenario: Plan contract contains deps and outputs
- **WHEN** downloading `artifacts/plan.json` after plan freeze
- **THEN** it contains dependency declarations and outputs contract data sourced from the selected template meta

### Requirement: Missing required parameters yield structured errors before run

SS MUST fail plan freeze (or earlier) with a structured error when required draft fields or required template parameters are missing.

#### Scenario: Missing params are rejected at plan freeze
- **WHEN** a required parameter is missing
- **THEN** `POST /v1/jobs/{job_id}/plan/freeze` fails with a structured error including missing field/param identifiers

### Requirement: Production gate disallows stub/fake dependencies and affects readiness

In production mode, SS MUST disallow stub LLM, fake runner, and fake object store, and `/health/ready` MUST report not-ready when any production requirement is violated.

#### Scenario: Readiness fails when stub/fake is configured
- **WHEN** starting SS in production mode with a stub/fake dependency configured or missing required env vars
- **THEN** `/health/ready` returns not-ready with a diagnosable reason

## Evidence sources (normative)

- Audit spec pack: `openspec/specs/ss-production-e2e-audit/spec.md`
- Audit run log + blockers: `openspec/_ops/task_runs/ISSUE-274.md`
- Primary code evidence referenced by the audit run log:
  - `src/domain/plan_service.py`
  - `src/domain/do_file_generator.py`
  - `src/domain/health_service.py`
  - `src/worker.py`
  - `src/config.py`
  - `src/api/routes.py`
  - `src/main.py`
  - `src/infra/llm_client_factory.py`
  - `src/infra/object_store_factory.py`

## Remediation scope (what “production-only chain” means)

1) **One authoritative business HTTP surface**: only `/v1/**` is allowed for job/draft/bundle/upload-session operations.
2) **Ops surface is production-grade**: health/metrics remain, but MUST not mask missing production dependencies.
3) **One authoritative execution chain**: do-template library is the only supported way to generate and run Stata do-files in the `/v1` journey.
4) **No runtime stubs/fakes**: stub LLM, fake Stata runner, fake object store, stub template ids MUST be removed from runtime wiring.

## Findings (all MUST be addressed)

### PROD-E2E-F001 (P0): Do-template library not wired; template selection is hard-coded

- Evidence:
  - `openspec/_ops/task_runs/ISSUE-274.md` → Blocking issue #1
  - `src/domain/plan_service.py` hard-codes `template_id="stub_descriptive_v1"`
  - `src/domain/do_file_generator.py` rejects any non-stub template
- Impact:
  - `/v1` cannot meet “template selection stability (not hard-coded)” and cannot execute the real do-template library.
- Single fix direction:
  - Wire the do-template library into the `/v1` plan+run chain by:
    - selecting a real `template_id` from `assets/stata_do_library/DO_LIBRARY_INDEX.json` via `DoTemplateSelectionService`
    - rendering via do-template meta + parameter binding
    - removing the stub template id + stub-only generator path from the production chain

### PROD-E2E-F002 (P0): Plan freeze lacks explicit dependencies and artifact/output contract

- Evidence:
  - `openspec/_ops/task_runs/ISSUE-274.md` → Blocking issue #2
  - downloaded `plan.json` contains no dependency declaration; `/v1` run chain does not consume do-template meta dependencies
- Impact:
  - Operators cannot preflight missing ado/SSC; missing dependency failures cannot be deterministically diagnosed/retried.
- Single fix direction:
  - Extend plan freeze output (plan step params) to include:
    - dependency declarations sourced from the selected template meta (`meta.dependencies`)
    - explicit outputs contract sourced from template meta (`meta.outputs`) and/or an explicit artifact index schema

### PROD-E2E-F003 (P0): Parameter binding is not a contract; missing params do not yield structured errors

- Evidence:
  - `openspec/_ops/task_runs/ISSUE-274.md` → Blocking issue #3
  - `src/domain/do_file_generator.py` generates a do-file even if `analysis_spec` is empty
  - v1 draft exposes `open_unknowns` but plan freeze does not enforce them
- Impact:
  - Silent wrong runs (incomplete bindings) and non-diagnosable retries; violates the audit gate.
- Single fix direction:
  - Define an explicit binding contract derived from do-template meta parameter specs + v1 draft blockers, and enforce it at plan-freeze time:
    - missing required params → structured error (error_code + context), plan is not frozen

### PROD-E2E-F004 (P0): Production safety gate missing (stub LLM / fake runner / fake object store allowed)

- Evidence:
  - `openspec/_ops/task_runs/ISSUE-274.md` → Blocking issue #4
  - `src/config.py`: `SS_LLM_PROVIDER` defaults to `stub`; `SS_UPLOAD_OBJECT_STORE_BACKEND` defaults to `fake`
  - `src/worker.py`: selects `FakeStataRunner` unless `SS_STATA_CMD` is set
  - `src/domain/health_service.py`: readiness reports `llm` as `ok=true` regardless of provider
- Impact:
  - High risk of deploying a “healthy” service that silently runs with stub/fake dependencies.
- Single fix direction:
  - Introduce a strict production gate enforced at startup + `/health/ready`:
    - production mode MUST reject stub LLM, fake runner, and fake object store
    - readiness MUST fail when production requirements are not satisfied
    - remove runtime stub/fake code paths (tests may use fakes under `tests/**` only)

### PROD-E2E-F005 (P0): Legacy non-`/v1` business endpoints create a second HTTP chain

- Evidence:
  - `openspec/_ops/task_runs/ISSUE-274.md` inventory shows unversioned `/jobs/**` mounted (hidden from OpenAPI)
  - `src/main.py` mounts `api_router` alongside `api_v1_router`
  - `src/api/routes.py` includes `jobs.router` and `draft.router` in both routers
- Impact:
  - Two business surfaces exist in production; auth/guards can diverge; operators cannot reason about the “real” surface.
- Single fix direction:
  - Remove the unversioned business surface from app wiring (do not mount job/draft routers without `/v1`).

### PROD-E2E-F006 (P1): Legacy job creation flow is still enabled by default

- Evidence:
  - `src/api/jobs.py`: `POST /jobs` exists (and is reachable under `/v1/jobs` via router mounting)
  - `src/config.py`: `v1_enable_legacy_post_jobs` defaults to `True`
- Impact:
  - Alternate job creation flow bypasses the audited redeem→token flow; increases prod ambiguity and attack surface.
- Single fix direction:
  - Remove legacy `POST /v1/jobs` and require task-code redemption as the only v1 job creation mechanism.

## Acceptance (production readiness gate)

The remediation is accepted only when:

1) Re-running the audit spec pack yields `READY`:
   - `openspec/specs/ss-production-e2e-audit/spec.md` key audit points all **PASS**
2) `/v1` journey uses a real do-template from `assets/stata_do_library/**` (no stub template ids)
3) Plan freeze returns:
   - selected template reference + rationale evidence
   - explicit parameter binding contract (missing → structured error)
   - explicit dependency declarations (missing → diagnosable + retryable)
   - explicit outputs contract/index
4) Production gate prevents “stub/fake in prod” and `/health/ready` reflects violations.

## Task cards (implementation plan)

All remediation work MUST be tracked via task cards in `openspec/specs/ss-production-e2e-audit-remediation/task_cards/`:

- `round-01-prod-a__PROD-E2E-R001.md` (F005)
- `round-01-prod-a__PROD-E2E-R002.md` (F006)
- `round-01-prod-a__PROD-E2E-R010.md` (F001)
- `round-01-prod-a__PROD-E2E-R011.md` (F001)
- `round-01-prod-a__PROD-E2E-R012.md` (F002)
- `round-01-prod-a__PROD-E2E-R013.md` (F001, F003)
- `round-01-prod-a__PROD-E2E-R020.md` (F002)
- `round-01-prod-a__PROD-E2E-R030.md` (F003)
- `round-01-prod-a__PROD-E2E-R040.md` (F004)
- `round-01-prod-a__PROD-E2E-R041.md` (F004)
- `round-01-prod-a__PROD-E2E-R042.md` (F004)
- `round-01-prod-a__PROD-E2E-R043.md` (F004)
- `round-01-prod-a__PROD-E2E-R090.md` (Acceptance gate)

