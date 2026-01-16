# Proposal: issue-487-p3-frontend-routing

## Why
The current frontend behaves like a pseudo-SPA: it reloads the page for navigation and stores key state (`jobId`, `view`) in `localStorage`, which causes flicker, state loss on refresh, and multi-tab interference. We need URL-driven navigation to support deep links and reliable state across refreshes and tabs.

## What Changes
- Introduce React Router for real client-side routing and navigation.
- Encode `jobId` and the current step in the URL (e.g. `/jobs/:jobId/upload`) rather than `localStorage`.
- Remove navigation flows that call `window.location.reload()` and replace them with route navigation.
- Keep existing UI/visuals unchanged; focus strictly on architecture and state location.

## Impact
- Affected specs: `rulebook/tasks/issue-487-p3-frontend-routing/specs/frontend-routing/spec.md`
- Affected code: `frontend/src/**`
- Breaking change: YES (URL structure + navigation behavior)
- User benefit: no reload flicker, deep links, refresh-safe state, and no cross-tab Job interference.
