# Design: Frontend architecture improvements (ss-ux-remediation)

## Goals

- Keep SS frontend URL-driven and refresh-safe (per `ss-frontend-architecture`).
- Make “loading / error / empty / locked” states explicit and reusable.
- Centralize local persistence (localStorage) and multi-tab hygiene.
- Improve interaction affordances without introducing a new UI framework.

## Constraints (non-negotiable)

- UI stays within Desktop Pro primitives and CSS variables (`frontend/src/styles/*.css`).
- No new component library (no Tailwind/MUI/Antd/shadcn).
- Routing rules remain canonical (`/new`, `/jobs/:jobId/upload|preview|status`, `/admin/*`).
- localStorage is for **persistence only**, never for route-driving state.

## Architectural changes (design intent)

### 1) Request lifecycle UX is a first-class concern

Problem: Many actions feel “silent” (no immediate feedback, unclear waiting).

Design:
- Standardize a per-request UX model: `idle → loading → success|error`.
- Add a global “busy” indicator for non-trivial waits (e.g., >300ms).
- Use per-component skeletons where content shape is known (tables, panels).
- Prefer bounded polling with clear timeout + retry affordance.

Implementation notes (anchors):
- API client: `frontend/src/api/client.ts` (single chokepoint for requests).
- Global UI surfaces: `frontend/src/main.tsx` + `frontend/src/components/*`.

### 2) Navigation is explicit, reversible, and communicates state

Problem: Users get lost between steps and cannot safely “go back”.

Design:
- Stepper becomes labeled and optionally clickable for completed steps.
- Provide explicit “返回上一步” entry points in step pages where safe.
- Dangerous “reset/redeem again” actions require confirmation and explain data loss.
- Browser title reflects step + job (multi-tab friendly).

Implementation notes (anchors):
- Routing + page shell: `frontend/src/main.tsx`
- Step pages: `frontend/src/features/step1/Step1.tsx`, `frontend/src/features/step2/Step2.tsx`, `frontend/src/features/step3/Step3.tsx`, `frontend/src/features/status/Status.tsx`

### 3) Local persistence is centralized and namespaced

Problem: Refresh and token expiry can silently wipe in-progress input.

Design:
- Extend `frontend/src/state/storage.ts` with explicit helpers for per-job form drafts (Step3 mappings/answers).
- Ensure cleanup is explicit after confirm/reset and on auth invalidation.
- Use `storage` events to detect multi-tab conflicts and present a safe resolution UI.

### 4) Accessibility baseline is built into shared components

Design:
- Modal must support Escape, focus trap, and keyboard navigation.
- Error panels and tables must be navigable with keyboard and screen readers.
- Prefer semantic HTML and visible focus styles in CSS.

## Non-goals

- Full redesign of the Desktop Pro visual system.
- Backend behavior changes beyond the scope of `BE-*` task cards.

