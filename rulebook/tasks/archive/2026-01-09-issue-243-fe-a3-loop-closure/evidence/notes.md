# Notes: issue-243-fe-a3-loop-closure

## Decisions
- Use `localStorage` snapshots keyed by `job_id` for refresh-resume (inputs upload/preview, draft preview, confirm lock).
- Implement Step 3 downgrade behavior strictly per `openspec/specs/ss-frontend-desktop-pro/spec.md`.

## Open questions / blockers
- Step 3 draft/patch contract still depends on CLI B-3 ALIGN-C004; implement best-effort calls + explicit downgrade when endpoints/fields missing.

## Later
- Consider extracting more shared UI primitives once more steps exist (avoid premature abstraction).
