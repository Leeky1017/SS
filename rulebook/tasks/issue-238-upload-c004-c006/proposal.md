# Proposal: issue-238-upload-c004-c006

## Why
SS v1 uploads need a presigned URL workflow (direct + multipart) that avoids routing bytes through the API, while ensuring finalize is strongly idempotent and safe under concurrency.

## What Changes
- Add v1 upload-sessions endpoints: create, refresh URLs, finalize.
- Enforce v1 limits (TTL <= 15min, multipart constraints, max sessions per job) via `src/config.py`.
- Persist finalized uploads into the existing inputs subsystem: `inputs/manifest.json` (schema_version=2), `job.json.inputs.*`, and artifacts index.
- Add CI-stable pytest coverage including anyio concurrency tests and a stress/bench plan.

## Impact
- Affected specs: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/`, `tests/`
- Breaking change: NO (new endpoints; existing inputs upload remains supported)
- User benefit: Reliable large-file uploads with explicit refresh/finalize semantics and concurrency safety.
