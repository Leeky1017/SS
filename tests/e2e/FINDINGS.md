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

- Input preview boundary cases:
  - Symptoms: hidden sheets were listed; formula cells could produce NaN and crash JSON serialization; password-protected `.xlsx` surfaced as a generic parse error.
  - Fix: filter `sheet_names` to visible sheets; render formulas as raw strings and coerce NaN/Inf to `null`; detect encrypted `.xlsx` containers and return a user-friendly `INPUT_PARSE_FAILED` message.
  - Evidence: `tests/e2e/layer2_inputs/test_input_processing_boundaries.py`

- LLM malformed output handling:
  - Symptoms: non-JSON/empty structured output could slip through and advance job state.
  - Fix: validate draft-preview structured output strictly; invalid/empty output returns `502 LLM_RESPONSE_INVALID` without advancing status.
  - Evidence: `tests/e2e/layer3_llm/test_llm_output_validation.py`

## Follow-ups (not fixed here)
- None tracked in this change (see `tests/e2e/COVERAGE.md` for remaining known gaps).
