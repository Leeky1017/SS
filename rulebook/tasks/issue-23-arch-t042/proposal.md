# Proposal: issue-23-arch-t042

## Why
Enable SS to execute queued jobs out-of-process with auditable per-attempt run directories and
bounded retries.

## What Changes
- Add a standalone worker entrypoint (`python -m src.worker`) that claims jobs from `WorkerQueue` and
  executes plan steps.
- Ensure each attempt gets a fresh `run_id` directory and archives artifacts for audit/debugging.
- Add configurable retry/backoff and attempt limits via `src/config.py`.

## Impact
- Affected specs: `openspec/specs/ss-worker-queue/spec.md`, `openspec/specs/ss-stata-runner/spec.md`
- Affected code: `src/config.py`, `src/domain/*`, `src/infra/*`, `src/worker.py`, `tests/*`
- Breaking change: NO
- User benefit: Workers can process jobs reliably with preserved evidence and bounded retries.
