# Spec: ss-frontend-backend-alignment

## Purpose

Define a **v1 frontend↔backend contract** that removes Step 3 “downgrade” paths: once the Desktop Pro frontend is shipped, the SS backend MUST align so the user journey runs end-to-end without missing-field fallbacks. This spec freezes the minimal required surface: task-code redeem + job token auth + Step 3 preview/patch/confirm contract + acceptance test gate.

## Related specs (normative)

- API surface + `/v1`: `openspec/specs/ss-api-surface/spec.md`
- Step 3 frontend consumption contract: `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Proxy parity upgrade (backend, partial overlap): `openspec/specs/backend-stata-proxy-extension/spec.md`

## Related legacy references (non-normative, semantic only)

- Redeem response shape reference (do not port entitlement/quota): `legacy/stata_service/frontend/src/api/stataService.ts` (`RedeemResponse`)

## Requirements

### Requirement: v1 task-code redeem MUST return a job token with fixed, idempotent semantics

SS MUST provide a v1 endpoint for redeeming a task code into a job-scoped token:

- Method + path: `POST /v1/task-codes/redeem`
- Authentication: no `Authorization` required
- Structured errors: all failures MUST use `{"error_code": "...", "message": "..."}` (SS `SSError` shape)

Request JSON (v1, fixed fields):
- `task_code`: string (required, non-empty)
- `requirement`: string (required field; may be empty string)

Response JSON (HTTP 200, fixed fields):
- `job_id`: string
- `token`: string
- `expires_at`: string (RFC3339)
- `is_idempotent`: boolean

Redeem idempotency rules (v1, write-locked):
- Redeem MUST be idempotent by `task_code`.
- Re-redeeming the same `task_code` MUST return the same `job_id`.
- Token MUST NOT rotate on repeated redeem for the same `task_code` (same `token` returned).
- `is_idempotent` MUST be `false` on the first successful redeem for a `task_code`, and `true` on subsequent successful redeems.
- Token TTL is fixed (v1): 7 days.
- `expires_at` MUST be refreshed on each successful redeem to `now + 7 days` (sliding expiration) and MUST be an RFC3339 timestamp.
- Redeem MUST NOT introduce entitlement/quota fields; specifically, the response MUST NOT include `entitlement`.

Redeem requirement persistence (v1):
- On first successful redeem, if `requirement` is non-empty, SS MUST persist it as the job requirement.
- On subsequent idempotent redeems, SS MUST NOT overwrite the persisted requirement (even if a different `requirement` is provided).

#### Scenario: Redeem returns fixed fields and a stable token
- **WHEN** `POST /v1/task-codes/redeem` is called with `{"task_code":"tc_demo_01","requirement":"..."}`
- **THEN** the response is HTTP `200` with JSON keys `job_id`, `token`, `expires_at`, `is_idempotent`

#### Scenario: Redeem is idempotent and does not rotate token
- **WHEN** the same `task_code` is redeemed twice
- **THEN** both responses return the same `job_id` and the same `token`

### Requirement: Job token auth MUST be enforced for redeem-created jobs, with a configurable legacy-create coexistence strategy

SS MUST support job-scoped auth via an HTTP header:
- Header: `Authorization: Bearer <token>`
- `<token>` is the `token` returned by `POST /v1/task-codes/redeem`

Auth scope (v1, write-locked):
- For jobs created via redeem, all job-scoped endpoints under `/v1/jobs/{job_id}/...` MUST require a valid Bearer token.
- `POST /v1/task-codes/redeem` MUST remain unauthenticated.
  - `POST /v1/task-codes/redeem` MUST be the only v1 job creation entrypoint; `POST /v1/jobs` MUST NOT be routable.
  - The auth requirement MUST apply to at least these v1 routes:
    - `POST /v1/jobs/{job_id}/inputs/upload`
    - `GET /v1/jobs/{job_id}/inputs/preview`
    - `GET /v1/jobs/{job_id}/draft/preview`
    - `POST /v1/jobs/{job_id}/draft/patch`
    - `POST /v1/jobs/{job_id}/confirm`
    - `GET /v1/jobs/{job_id}`
    - `GET /v1/jobs/{job_id}/artifacts`
    - `GET /v1/jobs/{job_id}/artifacts/{artifact_id:path}`
    - `POST /v1/jobs/{job_id}/run`

Auth error codes (v1, fixed set):

- HTTP `401` MUST use one of:
  - `AUTH_BEARER_TOKEN_MISSING`
  - `AUTH_BEARER_TOKEN_INVALID`
- HTTP `403` MUST use one of:
  - `AUTH_TOKEN_INVALID`
  - `AUTH_TOKEN_FORBIDDEN`

Auth semantics (v1):
- Missing `Authorization` header on an auth-required route MUST return HTTP `401` + `AUTH_BEARER_TOKEN_MISSING`.
- Non-Bearer or malformed header (including empty token) MUST return HTTP `401` + `AUTH_BEARER_TOKEN_INVALID`.
- A token that is not recognized MUST return HTTP `403` + `AUTH_TOKEN_INVALID`.
- A token that is recognized but does not authorize access to the `job_id` MUST return HTTP `403` + `AUTH_TOKEN_FORBIDDEN`.

#### Scenario: V1 job creation endpoint is not routable
- **WHEN** `POST /v1/jobs` is called
- **THEN** SS returns HTTP `404` (even when `frontend/dist` is served at `/`)

#### Scenario: Missing token is rejected with a stable 401 error_code
- **WHEN** `GET /v1/jobs/{job_id}/draft/preview` is called without `Authorization` for a redeem-created job
- **THEN** the response is HTTP `401` with `{"error_code":"AUTH_BEARER_TOKEN_MISSING","message":"..."}`

#### Scenario: Wrong token is rejected with a stable 403 error_code
- **WHEN** `GET /v1/jobs/{job_id}/draft/preview` is called with `Authorization: Bearer wrong_token` for a redeem-created job
- **THEN** the response is HTTP `403` with `{"error_code":"AUTH_TOKEN_FORBIDDEN","message":"..."}`

### Requirement: Step 3 draft preview MUST implement the frontend draft-v1 contract, including 202 pending

SS MUST implement the Step 3 preview endpoint:
- Method + path: `GET /v1/jobs/{job_id}/draft/preview`
- Auth: required for redeem-created jobs (see auth requirement)
- Query: `main_data_source_id` MAY be provided; if provided and not recognized for the job, SS MUST return HTTP `400` with structured error `INPUT_MAIN_DATA_SOURCE_NOT_FOUND`.

Response shape (HTTP 200, draft-v1 minimum, field names MUST match `frontend-stata-proxy-extension`):
- `draft_id`: string
- `decision`: `"auto_freeze" | "require_confirm" | "require_confirm_with_downgrade"`
- `risk_score`: number
- `status`: string
- `outcome_var`: string|null
- `treatment_var`: string|null
- `controls`: string[]
- `column_candidates`: string[] (MUST be present; may be empty)
- `data_quality_warnings`: `{type,severity,message,suggestion}`[] (MUST be present; may be empty)
- `stage1_questions`: `{question_id,question_text,question_type,options,priority}`[] (MUST be present; may be empty)
- `open_unknowns`: `{field,description,impact,blocking?,candidates?}`[] (MUST be present; may be empty)

Pending shape (HTTP 202, MUST be implemented):
- `status`: `"pending"`
- `message`: string
- `retry_after_seconds`: number (integer)
- `retry_until`: string (RFC3339)

Additional fields MAY be included for backward compatibility, but MUST NOT change or remove the draft-v1 fields above.

#### Scenario: Draft preview returns draft-v1 fields
- **WHEN** the backend returns HTTP `200` from `GET /v1/jobs/{job_id}/draft/preview`
- **THEN** the JSON response contains at least the draft-v1 keys `decision`, `risk_score`, `data_quality_warnings`, `stage1_questions`, and `open_unknowns`

#### Scenario: Draft preview pending uses a stable 202 shape
- **WHEN** the backend cannot yet provide a draft preview
- **THEN** it returns HTTP `202` with `retry_after_seconds` and `retry_until`

### Requirement: Step 3 draft patch MUST implement the frontend patch-v1 contract

SS MUST implement the Step 3 patch endpoint:
- Method + path: `POST /v1/jobs/{job_id}/draft/patch`
- Auth: required for redeem-created jobs

Request JSON (patch-v1, fixed fields):
- `field_updates`: object (required; may be empty object)

Response JSON (patch-v1, fixed fields):
- `status`: `"patched"`
- `patched_fields`: string[]
- `remaining_unknowns_count`: number (integer)
- `open_unknowns`: `{field,description,impact,blocking?,candidates?}`[]
- `draft_preview`: object (at minimum includes `outcome_var`, `treatment_var`, `controls`; extra fields allowed)

#### Scenario: Patch updates open_unknowns and returns an updated preview
- **WHEN** `POST /v1/jobs/{job_id}/draft/patch` is called with `{"field_updates":{"panel_id":"firm_id"}}`
- **THEN** the response is HTTP `200` with `remaining_unknowns_count` and `draft_preview`

### Requirement: Step 3 confirm MUST enforce backend-side blocking rules and persist confirmation into the runnable contract

SS MUST implement the Step 3 confirm endpoint:
- Method + path: `POST /v1/jobs/{job_id}/confirm`
- Auth: required for redeem-created jobs

Request JSON (confirm-v1, required fields; frontend sends empty objects when unused):
- `confirmed`: boolean
- `variable_corrections`: object (required; may be empty object)
- `answers`: object (required; may be empty object)
- `default_overrides`: object (required; may be empty object)
- `expert_suggestions_feedback`: object (required; may be empty object)

Response JSON (minimum fixed fields):
- `job_id`: string
- `status`: string
- `message`: string

Blocking rules (v1, enforced by backend; no frontend bypass):
- If `stage1_questions` in the latest preview is non-empty, confirm MUST reject unless every question has at least one selected answer in `answers`.
- Confirm MUST reject if any blocking open unknowns remain unresolved.
  - An unknown is blocking when `blocking == true` OR `impact` is `"high"`/`"critical"`.

On blocking failure, SS MUST return HTTP `400` with structured error:
- `error_code="DRAFT_CONFIRM_BLOCKED"`
- `message` describes what is missing (question ids and/or unknown fields)

Persistence and determinism (v1, write-locked):
- SS MUST persist the confirmation payload (`answers`, `expert_suggestions_feedback`, `variable_corrections`, `default_overrides`) in the job record so the run is reproducible.
- SS MUST include the confirmation payload in the plan/contract identity (plan id hash inputs) so changes to these fields change the derived plan id.

#### Scenario: Confirm rejects missing stage1 answers and blocking unknowns
- **WHEN** `POST /v1/jobs/{job_id}/confirm` is called while any blocking items remain
- **THEN** the response is HTTP `400` with `{"error_code":"DRAFT_CONFIRM_BLOCKED","message":"..."}`

#### Scenario: Confirm success returns minimum fields and queues the job
- **WHEN** `POST /v1/jobs/{job_id}/confirm` is called with all blocking items resolved
- **THEN** the response is HTTP `200` with `job_id` and a queued/executing `status`

### Requirement: Backend acceptance MUST be gated by ruff + pytest, including tokenized end-to-end coverage

Backend changes for this alignment MUST be accepted only when:
- `ruff check .` exits with code `0`
- `pytest -q` exits with code `0`

Pytest coverage MUST include:
- A tokenized critical path test: redeem → obtain token → call `inputs/upload`, `draft/preview`, `draft/patch`, `confirm` with the token.
- Auth rejection tests: missing token and wrong token for the same endpoints, asserting stable `error_code`.

#### Scenario: Required commands pass in CI
- **WHEN** `ruff check .` and `pytest -q` are executed
- **THEN** both exit with code `0`

#### Scenario: Tokenized journey is protected by pytest
- **WHEN** reviewing the test suite
- **THEN** it contains tests covering redeem→token→upload→preview→patch→confirm and missing/wrong-token rejections

## Task cards

Task cards for this spec live under: `openspec/specs/ss-frontend-backend-alignment/task_cards/`.
