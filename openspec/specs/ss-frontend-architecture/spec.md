# Spec: ss-frontend-architecture

## Purpose

Define SS frontend routing, state placement, and navigation conventions so the UI remains URL-driven, refresh-safe, and maintainable.

## Requirements

### Requirement: Routes follow canonical URL structure

The SS frontend MUST use React Router with the following canonical URL structure:

- New job flow: `/new`
- Job flow steps: `/jobs/:jobId/<step>`
- Admin UI: `/admin/*`

For the current job flow, the canonical step routes are:

- `/jobs/:jobId/upload`
- `/jobs/:jobId/preview`
- `/jobs/:jobId/status`

The root path `/` and any unknown route MUST redirect to `/new`.

`/jobs/:jobId` MUST be treated as an auto-router entry that redirects to a concrete step route and MUST NOT render step UI directly.

Adding a new page/step MUST follow this flow:

1. Add the route to `frontend/src/main.tsx` (prefer placing it under the `/` + `<App />` route tree).
2. Implement the page under `frontend/src/features/<feature>/` and read `jobId` via `useParams()`.
3. Navigate using `useNavigate()` / `<Link>` (no reload).
4. If the step should be resumable from `/jobs/:jobId`, update the auto-router redirect logic (redirect only).
5. Verify with `cd frontend && npm run build`.

#### Scenario: Unknown routes are safe
- **WHEN** a user navigates to an unknown path
- **THEN** the app redirects to `/new` (no blank screen)

#### Scenario: Job auto-route redirects to a concrete step
- **WHEN** a user navigates to `/jobs/:jobId`
- **THEN** the app redirects to a concrete step route like `/jobs/:jobId/upload` (never stays on `/jobs/:jobId`)

### Requirement: Route params are explicit and stable

All job routes MUST use the parameter name `:jobId` (NOT `:id`).

When constructing a job URL from a `jobId`, code MUST use `encodeURIComponent(jobId)`.

Components that require a job id MUST read it from `useParams().jobId` and treat missing/blank values as invalid.

#### Scenario: Adding a new step uses :jobId
- **WHEN** adding a new job step route
- **THEN** the route pattern is `jobs/:jobId/<step>` and the component reads `useParams().jobId`

### Requirement: URL owns navigation state; localStorage is for persistence only

The SS frontend MUST treat the URL as the source of truth for navigation state.

- URL MUST contain: `jobId` and the current step (`upload`, `preview`, `status`, ...).
- `localStorage` MAY contain: per-job snapshots/caches (e.g. input previews, draft preview), per-job auth tokens, and user preferences (e.g. theme).

The frontend MUST NOT store any route-driving state in `localStorage` (examples: `currentStep`, `view`, `lastRoute`, or a persisted `jobId` used to decide which page to render).

If a "resume" behavior is needed, it MUST be implemented by redirecting from an explicit auto-route (`/jobs/:jobId`) into an explicit step route, not by rendering different steps on the same URL.

#### Scenario: Refresh keeps the same step
- **WHEN** a user refreshes `/jobs/:jobId/preview`
- **THEN** the app stays on `/jobs/:jobId/preview` and restores only non-routing data (API fetch and/or per-job snapshots)

### Requirement: localStorage access is centralized and namespaced

All `localStorage` reads/writes MUST be centralized in dedicated modules (no ad-hoc keys in components):

- Job flow: `frontend/src/state/storage.ts` (`ss.frontend.v1.*`, `ss.auth.v1.*`)
- Admin: `frontend/src/features/admin/adminStorage.ts` (`ss.admin.*`)
- Theme: `frontend/src/state/theme.ts` (`ss.theme`)

#### Scenario: Adding a new snapshot key is centralized
- **WHEN** adding a new persisted per-job snapshot
- **THEN** the key and helpers are added to `frontend/src/state/storage.ts` and components only call the helper functions

### Requirement: Navigation uses React Router APIs (no reload)

In-app navigation MUST use `useNavigate()` and/or `<Link to="...">`.

Code MUST NOT call `window.location.reload()` or assign to `window.location` for in-app navigation.

Redirects SHOULD use `<Navigate replace />` (or `navigate(..., { replace: true })`) when the back button should not return to the intermediate route.

#### Scenario: Navigation does not reload
- **WHEN** moving from `/new` to `/jobs/:jobId/upload`
- **THEN** the transition uses router navigation (no full page reload)

### Requirement: Error recovery navigates to a safe route

When a step route requires `jobId` but it is missing/invalid, the page MUST:

- present a user-facing error panel, and
- offer an action to navigate back to `/new` (and reset any relevant persisted state).

For recoverable request failures, the UI SHOULD provide a retry action that re-runs the failing operation without changing the URL.

#### Scenario: Missing jobId offers recovery
- **WHEN** rendering a step route and `useParams().jobId` is missing/blank
- **THEN** the UI offers a button that navigates to `/new`

### Requirement: Frontend code is organized by feature

New UI pages/flows MUST live under `frontend/src/features/<feature>/`.

Shared UI components MUST live under `frontend/src/components/`.

Shared state/hooks MUST live under `frontend/src/state/`.

#### Scenario: Adding a new page follows the layout
- **WHEN** adding a new page
- **THEN** it is placed under `frontend/src/features/` and shared pieces go under `frontend/src/components/` or `frontend/src/state/`
