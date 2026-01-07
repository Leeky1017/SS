# Proposal: issue-126-ux-b001-inputs-upload-preview

## Why
P0 blocker: SS currently lacks dataset upload/preview, preventing the UX loop from completing and blocking deterministic input fingerprinting for downstream planning/execution.

## What Changes
- ADDED: `POST /v1/jobs/{job_id}/inputs/upload` for CSV/Excel/DTA upload (multipart form-data)
- ADDED: `GET /v1/jobs/{job_id}/inputs/preview` for bounded preview (columns + inferred types + sample rows)
- ADDED: job-scoped persistence under `inputs/` with `inputs/manifest.json` and `job.inputs.{manifest_rel_path,fingerprint}` updates
- ADDED: structured errors for empty file / unsupported format / parse failure

## Impact
- Affected specs: `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B001.md`
- Affected specs: `openspec/specs/ss-api-surface/spec.md`, `openspec/specs/ss-job-contract/spec.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/`, `tests/`
- Breaking change: NO
- User benefit: Users can upload a dataset for a job, preview schema/sample rows, and persist an inputs manifest + fingerprint for deterministic planning.
