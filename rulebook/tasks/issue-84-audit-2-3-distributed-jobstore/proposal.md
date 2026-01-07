# Proposal: issue-84-audit-2-3-distributed-jobstore

## Why
The audit flagged that the current single-node file persistence model does not provide reliable consistency guarantees under multi-node deployment (e.g., NFS cache/atomicity issues). SS needs an explicit distributed JobStore decision and a safe migration path from the file backend.

## What Changes
- Define the minimal JobStore backend interface and required guarantees (consistency, concurrency, failure modes).
- Compare at least two backend options (Redis, PostgreSQL) with operational tradeoffs.
- Produce a concrete migration plan from the current file backend to the chosen distributed backend (rollout + fallback).
- Add minimal plumbing so the backend can be selected via `src/config.py` (default remains file backend).

## Impact
- Affected specs: new `openspec/specs/ss-job-store/spec.md` (+ decision doc under same spec dir)
- Affected code: `src/config.py`, `src/api/deps.py`, `src/worker.py`, `src/cli.py` (backend selection wiring)
- Breaking change: NO (default backend remains file)
- User benefit: production-ready path to multi-node deployment without relying on unsafe shared filesystem semantics
