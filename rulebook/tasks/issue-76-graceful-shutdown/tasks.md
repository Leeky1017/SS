## 1. Implementation
- [ ] 1.1 Add API lifespan hooks + shutdown gate + structured logs
- [ ] 1.2 Add worker SIGTERM/SIGINT handling and stop-claiming behavior
- [ ] 1.3 Bound in-flight work during shutdown and ensure claim/job outcomes are explicit

## 2. Testing
- [ ] 2.1 Add tests for API startup/shutdown events and shutdown gate behavior
- [ ] 2.2 Add tests for worker shutdown behavior (stop claiming, bounded in-flight)
- [ ] 2.3 Run `ruff check .` and `pytest -q`

## 3. Documentation
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-76.md` with commands/outputs/evidence
