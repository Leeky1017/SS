## 1. Implementation
- [ ] 1.1 Add LLM timeout/retry/backoff config (`src/config.py`)
- [ ] 1.2 Enforce timeout + retries in the LLM infra adapter with structured logs
- [ ] 1.3 Wire config into DI (`src/api/deps.py`)

## 2. Testing
- [ ] 2.1 Add timeout + retry regression tests using a fake LLM client
- [ ] 2.2 Ensure logs include `job_id`, `attempt`, `timeout_seconds`

## 3. Evidence
- [ ] 3.1 Record run evidence: `ruff check .`, `pytest -q`, `openspec validate --specs --strict --no-interactive`

