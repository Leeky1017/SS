# Proposal: issue-80-jobstore-race-protection

## Why
The audit identified a lost-update risk: the file backend is atomically written, but the higher-level read → modify → save flow is not atomic, so concurrent writers can silently overwrite each other.

## What Changes
- Add a persisted monotonic job `version` field suitable for optimistic concurrency control.
- Make `JobStore.save()` detect stale writes and fail with a structured conflict error (no silent overwrites).
- Keep state transitions enforced by the domain state machine (logical correctness remains in domain, not storage).
- Add tests that reproduce the conflict scenario (two writers based on the same initial version).

## Impact
- Affected specs: `openspec/specs/ss-job-contract/README.md`
- Affected code: `src/domain/models.py`, `src/infra/job_store.py`, `src/infra/exceptions.py`, tests
- Breaking change: NO (read supports prior schema; write moves to the new current schema)
- User benefit: prevents silent lost updates under API/worker and multi-worker concurrency

