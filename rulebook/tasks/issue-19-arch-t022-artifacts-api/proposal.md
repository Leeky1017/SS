# Proposal: issue-19-arch-t022-artifacts-api

## Why
Expose job artifacts as first-class API resources and add an explicit enqueue-only run trigger to align with `openspec/specs/ss-api-surface/spec.md`.

## What Changes
- Add artifacts index + safe download endpoints under `/jobs/{job_id}/artifacts`.
- Add `POST /jobs/{job_id}/run` to transition a job to `queued` without executing within the API process.
- Add tests for path safety, missing artifacts, and idempotent run triggering.

## Impact
- Affected specs: `openspec/specs/ss-api-surface/spec.md`, `openspec/specs/ss-job-contract/spec.md`, `openspec/specs/ss-state-machine/spec.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/`, `tests/`
- Breaking change: NO
- User benefit: clients can list/download artifacts safely and trigger runs explicitly.

