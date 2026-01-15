# E2E findings

This file records issues discovered while building the suite (when the expected behavior was not implemented yet).

## Fixed in this change

- Post-confirm mutation was not locked:
  - Symptoms: users could still upload inputs / patch draft after confirmation, risking mismatch between frozen plan and inputs.
  - Fix: introduced `JOB_LOCKED` (409) and enforced it in inputs upload and draft patch paths.
  - Evidence: `tests/e2e/layer4_confirm/test_confirm_and_locking.py`

- Concurrent confirm surfaced version conflicts (409) instead of being idempotent:
  - Symptoms: two near-simultaneous confirms could return `JOB_VERSION_CONFLICT` for one request.
  - Fix: reduced conflict-prone writes and made `JobService.trigger_run()` tolerate `JobVersionConflictError` by returning the latest queued/running state.
  - Evidence: `tests/e2e/layer6_state/test_state_machine_and_concurrency.py`

- Execution retry semantics:
  - Symptoms: deterministic “fail then user retry” scenarios were hard to validate if execution errors were treated as retriable within the worker loop.
  - Fix: make the E2E fake runner emit a non-retriable error code (`STATA_DEPENDENCY_MISSING`) so jobs fail fast and the explicit user retry path is testable.
  - Evidence: `tests/e2e/layer5_execution/test_execution_and_retry.py`

## Follow-ups (not fixed here)

- Expand input corpus coverage:
  - password-protected Excel, hidden sheets, formula-heavy sheets, extremely large datasets, and pathological column names/encodings.

- Expand LLM malformed-output coverage:
  - invalid JSON payloads, structurally empty drafts, and partial structured fields (beyond provider exception/timeout).
