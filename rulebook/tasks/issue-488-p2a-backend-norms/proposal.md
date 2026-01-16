# Proposal: issue-488-p2a-backend-norms

## Summary

Document backend/general development norms that are currently implicit or scattered:
- API error handling contract (structured errors, error code conventions, no stack traces).
- Structured logging contract (event codes, required context, required log points, log levels).
- Job state machine rules (allowed transitions, validation, concurrency safety via versioning).
- Optional: testing guidance touch-ups for adding boundary/E2E coverage.

## Scope

- Documentation-only change (OpenSpec + AGENTS pointers). No code modifications.

## Impact

- Reduces future implementation drift by making current practices explicit and enforceable.
- Gives AI agents a concrete checklist for errors/logs/state changes in backend work.

