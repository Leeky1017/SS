# Proposal: issue-233-upload-c001-c003

## Why
SS needs an inputs upload core that supports large files and high concurrency without routing bytes through the API server, while preserving the existing `inputs/manifest.json` + `inputs/preview` loop. Before wiring upload sessions + finalize, we must freeze the v1 contract and land bundle declaration + object-store boundaries.

## What Changes
- Freeze `ss-inputs-upload-sessions` v1 contract in `openspec/specs/ss-inputs-upload-sessions/spec.md` (fields, error codes, idempotency/concurrency, fixed limits/env keys).
- Add an object storage domain port + infra adapters:
  - S3-compatible adapter (provider-injected; domain has no SDK dependency)
  - Fake adapter for pytest (including concurrent direct/multipart semantics)
- Implement bundle endpoints:
  - `POST /v1/jobs/{job_id}/inputs/bundle`
  - `GET /v1/jobs/{job_id}/inputs/bundle`
  - persisted file role model + stable `file_id` + duplicate filename allowed

## Impact
- Affected specs:
  - `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Affected code:
  - `src/domain/*` (new ports + services)
  - `src/infra/*` (object store adapters)
  - `src/api/*` (bundle endpoints)
  - `tests/*` (bundle + fake object store tests)
- Breaking change: NO
- User benefit: stable v1 upload contract + recoverable multi-file bundle declaration as a foundation for upload sessions + finalize.
