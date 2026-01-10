# ISSUE-342
- Issue: #342
- Branch: task/342-prod-e2e-r020
- PR: <fill-after-created>

## Plan
- Add dependency preflight + structured run error details
- Make failed jobs retryable via /v1/jobs/{job_id}/run
- Add tests + capture evidence (missing → fix → retry)

## Runs
### 2026-01-10 lint+tests
- Command: `ruff check .`
- Key output: `All checks passed!`

### 2026-01-10 tests
- Command: `pytest -q`
- Key output: `179 passed, 5 skipped in 9.64s`
- Evidence: `tests/test_worker_service.py::test_worker_service_when_dependency_missing_writes_structured_error_and_retry_succeeds`

### 2026-01-10 tests (post-refactor)
- Command: `pytest -q`
- Key output: `179 passed, 5 skipped in 8.40s`
- Evidence: `tests/test_worker_service_pre_run_errors.py::test_worker_service_when_dependency_missing_writes_structured_error_and_retry_succeeds`
