# Spec: frontend-routing (issue-487)

## Purpose

Replace the pseudo-SPA navigation with real client-side routing so the frontend can deep-link to a specific Job step, persist state across refresh, and avoid cross-tab interference.

## Scope

- Frontend-only refactor under `frontend/src/`.
- No backend API changes.
- No visual/UI redesign: keep existing look and layout.

## Requirements

### R1: URL-driven navigation (React Router)

The frontend MUST use a routing system for page transitions (no `window.location.reload()`-based navigation).

#### Scenario: navigation does not reload the page
- **GIVEN** the user is on `/new`
- **WHEN** they proceed to the next step
- **THEN** the app navigates via the router and the browser does not reload.

### R2: Job identity is in the URL

The `jobId` MUST be carried in the URL for all job-specific pages (e.g. `/jobs/:jobId/upload`).

#### Scenario: refresh keeps the same job context
- **GIVEN** the user is on `/jobs/123/upload`
- **WHEN** they refresh the page
- **THEN** the app renders the upload step for job `123` without relying on `localStorage`.

### R3: Deep links to steps are supported

The app MUST allow direct access to a specific Job step via URL.

#### Scenario: deep link opens preview page
- **GIVEN** the user opens `/jobs/123/preview` in a new tab
- **WHEN** the page loads
- **THEN** the preview step for job `123` renders.

### R4: Multi-tab isolation

Two tabs working on different jobs MUST NOT interfere with each other via shared storage of `jobId`/step state.

#### Scenario: tabs do not conflict
- **GIVEN** Tab A is on `/jobs/aaa/upload`
- **AND** Tab B is on `/jobs/bbb/preview`
- **WHEN** Tab A progresses steps
- **THEN** Tab B stays on job `bbb` and its step route remains unchanged.

