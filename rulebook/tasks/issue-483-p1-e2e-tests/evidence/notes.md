# Notes: issue-483-p1-e2e-tests

## Intent
- E2E suite targets boundary discovery: tests encode explicit expected outcomes; if an edge is mishandled, we either fix it or record it as a follow-up finding (without silently ignoring).

## Working assumptions
- Use FastAPI dependency overrides to inject deterministic fakes (LLM, runner, queue/store).
- Prefer testing stable structured errors (`error_code`, `message`) over fragile exact strings.

## Findings (draft)
- (to be filled) Locking gaps (e.g., mutate-after-confirm) if discovered.
- (to be filled) Concurrency UX gaps (e.g., version conflict surfacing to user) if discovered.

