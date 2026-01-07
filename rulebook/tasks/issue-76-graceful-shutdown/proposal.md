# Proposal: issue-76-graceful-shutdown

## Why
The audit found SS lacks a coordinated graceful shutdown path for the API and worker. Abrupt shutdown can leave queue claims unacked, jobs stuck in `running`, and in-flight Stata/LLM work interrupted without bounded cleanup or clear logs.

## What Changes
- Add FastAPI lifespan hooks and a shutdown gate to stop accepting new requests while shutting down.
- Add worker SIGTERM/SIGINT handling to stop claiming new jobs and to bound in-flight work during shutdown.
- Emit structured startup/shutdown events for both processes and ensure claims are acked/released deterministically.

## Impact
- Affected specs: `openspec/specs/ss-audit-remediation/spec.md`, `openspec/specs/ss-audit-remediation/task_cards/phase-1__graceful-shutdown.md`
- Affected code: `src/main.py`, `src/worker.py`, worker shutdown helpers, related tests
- Breaking change: NO
- User benefit: predictable shutdown behavior, fewer stuck jobs, and clearer operational logs

## 1. Implementation
- [ ] 1.1 Add API lifespan + shutdown gate + logs
- [ ] 1.2 Add worker signal handling and shutdown controller
- [ ] 1.3 Bound in-flight work and ensure explicit job/claim outcomes

## 2. Testing
- [ ] 2.1 Add tests for API lifecycle and worker shutdown behavior
- [ ] 2.2 Run `ruff check .` and `pytest -q` and record outputs

## 3. Documentation
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-76.md` with commands/outputs/evidence
