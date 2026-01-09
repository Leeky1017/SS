# Notes: issue-232-fe-c001-003

## Decisions
- Keep Desktop Pro visual system as source of truth: `index.html` + `assets/desktop_pro_*.css`.
- Dev default should run without backend: allow explicit mock mode in dev while preserving `VITE_REQUIRE_TASK_CODE` gate for fallback behavior.

## Open Questions
- None (Step 1 only; later steps in FE-C004+).

## Later
- Add small `vitest` suite for API error model + localStorage helpers (not required for FE-C001–003 acceptance).
