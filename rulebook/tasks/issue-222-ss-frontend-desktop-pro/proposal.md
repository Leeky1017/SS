# Proposal: issue-222-ss-frontend-desktop-pro

## Why
SS needs a real, maintainable Web frontend (beyond the single-file `index.html`) that preserves the Desktop Pro design system while integrating the current `/v1` API for an end-to-end UX loop.

## What Changes
- Add new OpenSpec `openspec/specs/ss-frontend-desktop-pro/spec.md` defining:
  - `frontend/` project shape (React + TypeScript + Vite)
  - Desktop Pro CSS primitives + variable semantics reuse
  - v1 UX loop endpoints and UI flow
  - Step 3 professional confirmation UX (with a clear downgrade strategy)
- Add 6 task cards (FE-C001–FE-C006) to break implementation into reviewable, parallelizable steps.
- Add run log `openspec/_ops/task_runs/ISSUE-222.md`.

## Impact
- Affected specs:
  - `openspec/specs/ss-frontend-desktop-pro/spec.md` (new)
- Affected code:
  - None (docs-only in this issue)
- Breaking change: NO
- User benefit: a production-grade frontend plan with a strict design system and API-aligned UX loop.
