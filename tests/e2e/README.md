# SS E2E tests (system-layer coverage)

Run:

```bash
pytest -q tests/e2e
```

Design:
- In-process API calls via `httpx` + `ASGITransport` (no external network).
- FastAPI dependency overrides inject deterministic fakes (LLM, runner, stores).
- Stata execution has a fake-runner path; real-Stata smoke tests auto-skip when unavailable.

Structure:
- `layer1_api_entry/` — request/response and structured error behavior for core endpoints
- `layer2_inputs/` — input formats, encoding, Excel edge cases
- `layer3_llm/` — LLM failure/retry/state preservation
- `layer4_confirm/` — confirm gating, idempotency, locking
- `layer5_execution/` — worker execution success/failure/retry (fake runner; real Stata optional)
- `layer6_state/` — illegal transitions, concurrency safety, task-code idempotency

