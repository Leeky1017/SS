## 1. Implementation
- [ ] 1.1 Define JobStore backend interface + required guarantees (spec-first)
- [ ] 1.2 Implement backend selection plumbing (config + factory, default=file)
- [ ] 1.3 Keep dependency injection explicit (API/worker/CLI assembly only)

## 2. Testing
- [ ] 2.1 Add unit tests for backend selection and unsupported backend error path
- [ ] 2.2 Run `ruff check .` and `pytest -q`

## 3. Documentation
- [ ] 3.1 Add OpenSpec: JobStore backend interface + guarantees
- [ ] 3.2 Write decision + migration plan (Redis vs Postgres, rollout + fallback) and record paths in run log
