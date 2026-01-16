# Proposal: issue-493-frontend-dev-spec

## Why
P3 (Issue #487) introduced React Router and URL-driven navigation, but the conventions are currently only implied by implementation. We need a short, canonical spec to keep future frontend work consistent (routes, where state lives, how navigation works) and to reduce regressions.

## What Changes
- Add a new OpenSpec document describing frontend routing/state/navigation conventions.
- Add an AGENTS.md pointer to the new spec.
- Verify the current frontend builds `frontend/dist/` and record evidence in the run log.

## Impact
- Affected specs: `openspec/specs/ss-frontend-architecture/spec.md`
- Affected code: documentation only (no runtime behavior changes)
- Breaking change: NO
- User benefit: consistent URL-driven routing, clearer state placement rules, and safer contributions.
