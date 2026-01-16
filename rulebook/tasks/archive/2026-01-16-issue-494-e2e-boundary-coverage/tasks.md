## 1. Implementation
- [ ] 1.1 Add input-boundary E2E tests (password-protected Excel, hidden sheets, formulas, huge dataset, pathological columns)
- [ ] 1.2 Add LLM malformed-output E2E tests (non-JSON/truncated, missing fields, empty draft)
- [ ] 1.3 Add execution-failure E2E tests (timeout + nonzero exit), extending fakes where needed
- [ ] 1.4 Fix backend gaps revealed by the new tests (or create follow-up Issues and mark tests xfail)

## 2. Testing
- [ ] 2.1 Run `pytest -v tests/e2e/`
- [ ] 2.2 Run `ruff check .`

## 3. Documentation
- [ ] 3.1 Update `tests/e2e/COVERAGE.md` (reduce known gaps)
- [ ] 3.2 Update `tests/e2e/FINDINGS.md` for any discovered gaps
- [ ] 3.3 Update `ERROR_CODES.md` when introducing new stable error codes
