# Tasks: PROD-E2E-R042

## Implementation

- Remove `FakeStataRunner` fallback wiring from `src/worker.py`; require `SS_STATA_CMD` at startup.
- Ensure logs include a stable `error_code` and missing env var context when failing.
- Remove runtime fake runner implementation from `src/**`; keep test fakes under `tests/**`.
- Update tests to inject the `tests/**` fake runner instead of importing runtime fake.

## Validation

- `ruff check .`
- `pytest -q`

