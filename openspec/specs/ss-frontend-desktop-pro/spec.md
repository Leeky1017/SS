# Spec: ss-frontend-desktop-pro

## Purpose

Ship a standalone, maintainable SS Web frontend under `frontend/` that faithfully reproduces the existing Desktop Pro UI (`index.html` + `assets/desktop_pro_*.css`) while integrating the current `/v1` API to complete the minimum user loop: redeem (task code) → upload → preview → blueprint → confirm → status/artifacts.

## Related specs (normative)

- Constitutional constraints: `openspec/specs/ss-constitution/spec.md`
- API surface + `/v1`: `openspec/specs/ss-api-surface/spec.md`
- Job contract + artifacts rules: `openspec/specs/ss-job-contract/spec.md`
- UX loop definition (v1): `openspec/specs/ss-ux-loop-closure/spec.md`
- Step 3 professional confirmation UX: `openspec/specs/frontend-stata-proxy-extension/spec.md`

## Requirements

### Requirement: The frontend MUST be a standalone project rooted at `frontend/`

SS MUST contain a standalone frontend project at repository root `frontend/` (MUST NOT reuse `legacy/stata_service/frontend/`).
The project MUST be buildable and runnable with:
- `cd frontend && npm ci && npm run build`
- `cd frontend && npm run dev` (manual acceptance)

#### Scenario: Frontend builds in CI
- **WHEN** `cd frontend && npm ci && npm run build` is executed
- **THEN** it exits with code `0` and produces a production bundle

### Requirement: Desktop Pro design primitives and CSS variables MUST be the only UI system

The frontend UI MUST replicate the Desktop Pro design system used by `index.html`:
- reuse the CSS variable semantics from `assets/desktop_pro_theme.css` (e.g., `--surface`, `--border`, `--text-dim`, `--accent`, `--success`, `--error`)
- keep the primitive classnames or a traceable mapping: `panel`, `section-label`, `btn` (`btn-primary`/`btn-secondary`), `data-table`, `mono`
- support the light/dark theme toggle using the `data-theme` attribute (`light`/`dark`)

The frontend MUST NOT introduce a new visual system or component library (no Tailwind, MUI, Antd, shadcn, etc.).

#### Scenario: UI stays within the Desktop Pro system
- **WHEN** reviewing `frontend/` dependencies and CSS sources
- **THEN** no new UI framework is added and Desktop Pro CSS variables drive the UI

### Requirement: API base URL MUST be configurable and MUST target `/v1`

All API requests from the frontend MUST be issued under `/v1` (stable API surface).
The frontend MUST support environment-based base URL injection via `VITE_API_BASE_URL`:
- default: `/v1` (same-origin + versioned path)
- example override: `https://ss.example.com/v1`

For local development, the frontend MUST support a dev-proxy workflow (e.g., Vite proxy) so `VITE_API_BASE_URL` can remain `/v1` while the dev server forwards `/v1/*` to the configured backend origin.

The frontend MUST:
- send a per-request id as `X-SS-Request-Id`
- show the last request id in the UI error panel for debugging

#### Scenario: A request includes a request id
- **WHEN** the frontend calls `POST /v1/task-codes/redeem`
- **THEN** it includes `X-SS-Request-Id: 0123456789abcdef` and shows the request id when the request fails

### Requirement: Production entry MUST redeem a task code and persist an auth token

The default production entry flow MUST be:
1) User inputs `task_code` and `requirement`
2) Frontend calls `POST /v1/task-codes/redeem`
3) Backend returns `{job_id, token}`
4) Frontend persists the token and resumes the UX loop for that `job_id`

The frontend MUST persist:
- `ss.last_job_id` = the redeemed `job_id`
- `ss.auth.v1.{job_id}` = the redeemed `token`

#### Scenario: Redeem succeeds and persists token
- **WHEN** the user submits `task_code` + `requirement` and the frontend receives `{job_id, token}` from `POST /v1/task-codes/redeem`
- **THEN** the token is persisted under `ss.auth.v1.{job_id}` and `ss.last_job_id` is updated to that `job_id`

### Requirement: Step 1 MUST provide guided analysis method selection for requirement drafting

To reduce vague requirements and improve downstream template/capability selection, Step 1 SHOULD provide an optional guided method selection UI (category → sub-method) that generates an editable structured requirement template.

This MUST:
- render a small set of analysis categories as clickable cards (including a “free description” option)
- show sub-method options for the selected category (except “free description”)
- populate the requirement textarea with a structured template when a sub-method is selected
- keep the generated template fully editable before submission

#### Scenario: Selecting a sub-method generates an editable requirement template
- **GIVEN** the user is at Step 1 and the requirement textarea is editable
- **WHEN** the user selects an analysis category and then selects a sub-method
- **THEN** the UI populates the requirement textarea with a structured template
- **AND** the user can freely edit the generated text before submission

#### Scenario: Free description keeps the textarea empty
- **GIVEN** the user is at Step 1
- **WHEN** the user selects “free description”
- **THEN** the UI does not auto-fill a template and keeps the textarea empty

### Requirement: Task code requirement MUST be gated by `VITE_REQUIRE_TASK_CODE`

The frontend MUST gate whether the user must provide a task code:
- If `VITE_REQUIRE_TASK_CODE=1`, the UI MUST require a non-empty `task_code`.
- If `VITE_REQUIRE_TASK_CODE` is unset or `0`, the UI MAY allow an empty `task_code` and MUST synthesize a non-empty dev task code when calling `POST /v1/task-codes/redeem`.

#### Scenario: Task code is required in production builds
- **GIVEN** `VITE_REQUIRE_TASK_CODE=1`
- **WHEN** the user tries to start without a `task_code`
- **THEN** the UI shows a validation error and no `POST /v1/task-codes/redeem` request is made

### Requirement: Auth token MUST be attached to all `/v1/**` requests and MUST be cleared on 401/403

When an auth token exists for the current job, every request under `/v1/**` MUST include:
- `Authorization: Bearer token_0123456789abcdef`

If any `/v1/**` request returns `401` or `403`, the frontend MUST:
- remove the stored token for the current job (`ss.auth.v1.{job_id}`)
- show a clear message: “Task Code 已失效/未授权，需要重新兑换”
- guide the user back to the redeem step

#### Scenario: Unauthorized clears token and guides re-redeem
- **GIVEN** `ss.auth.v1.{job_id}` exists for the current job
- **WHEN** a `/v1/**` request returns `401` or `403`
- **THEN** `ss.auth.v1.{job_id}` is cleared and the UI prompts the user to redeem again

### Requirement: The v1 UX loop MUST be usable end-to-end from the frontend

The frontend MUST implement a minimum usable flow aligned with backend `/v1` endpoints:
1) Redeem task code (production): `POST /v1/task-codes/redeem` → `{job_id, token}`
2) Upload dataset: `POST /v1/jobs/{job_id}/inputs/upload`
3) Inputs preview: `GET /v1/jobs/{job_id}/inputs/preview`
4) Blueprint precheck: `GET /v1/jobs/{job_id}/draft/preview`
5) Confirm + enqueue: `POST /v1/jobs/{job_id}/confirm`
6) Status + artifacts:
   - `GET /v1/jobs/{job_id}`
   - `GET /v1/jobs/{job_id}/artifacts`
   - `GET /v1/jobs/{job_id}/artifacts/{artifact_id:path}`

#### Scenario: User completes the loop and reaches artifacts
- **GIVEN** the SS backend is running and reachable via `VITE_API_BASE_URL`
- **WHEN** the user completes redeem → upload → preview → blueprint → confirm
- **THEN** the frontend can poll `GET /v1/jobs/{job_id}` until a terminal state
- **AND** the user can list artifacts and download at least one artifact file

### Requirement: Step 3 “Blueprint 预检” MUST implement the professional confirmation UX with defined downgrade behavior

Step 3 MUST implement the interaction model defined by:
- `openspec/specs/frontend-stata-proxy-extension/spec.md`

The frontend MUST support a usable downgrade when the backend does not yet provide the full draft/patch contract:
- If `GET /v1/jobs/{job_id}/draft/preview` does not contain `data_quality_warnings`, hide the warnings panel.
- If it does not contain `stage1_questions` or `open_unknowns`, hide the clarification/gating panel and do not block confirmation on missing answers.
- If variable-correction candidates are missing:
  - use inputs preview `columns[].name` as dropdown candidates;
  - if still empty, render variables read-only and hide correction dropdowns.
- If `POST /v1/jobs/{job_id}/draft/patch` is not available (404/501), disable/hide “应用澄清并刷新预览” and show a non-blocking inline hint.
- If `decision` is absent, do not show the downgrade-risk modal; confirmation proceeds normally.
- After a successful confirm, Step 3 MUST enter a locked read-only state (mapping/clarification inputs disabled; locked banner shown).

#### Scenario: Missing backend draft/patch features do not break Step 3
- **GIVEN** `GET /v1/jobs/{job_id}/draft/preview` returns the current minimal `DraftPreviewResponse`
- **WHEN** the user opens Step 3 and confirms
- **THEN** the UI remains usable (no crash) with unavailable panels hidden/disabled
- **AND** Step 3 transitions to a locked state after confirm success

### Requirement: The frontend MUST persist local state to support refresh/resume

The frontend MUST persist enough client state to allow refresh-resume:
- `job_id` and current step/view
- requirement text
- `task_code` (if set by the user)
- token (stored under `ss.auth.v1.{job_id}`; referenced via `ss.last_job_id`)
- inputs preview + blueprint preview snapshots (best-effort)

#### Scenario: Refresh resumes the last job
- **GIVEN** a user has created a job and uploaded inputs
- **WHEN** the user refreshes the page
- **THEN** the frontend restores the last job context and allows continuing from the next step
