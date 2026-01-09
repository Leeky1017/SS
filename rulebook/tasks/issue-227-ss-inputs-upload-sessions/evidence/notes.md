# Notes: issue-227-ss-inputs-upload-sessions

## Existing SS inputs contracts to align with
- Inputs upload + preview:
  - `POST /v1/jobs/{job_id}/inputs/upload`
  - `GET /v1/jobs/{job_id}/inputs/preview`
- Inputs persistence:
  - job workspace `inputs/`
  - `inputs/manifest.json` (schema_version=2 datasets list)
  - `job.json.inputs.manifest_rel_path` + `job.json.inputs.fingerprint`
- Multi-tenant: `X-SS-Tenant-ID` (`openspec/specs/ss-multi-tenant/spec.md`)

## Legacy semantics reference (field shapes)
- `legacy/stata_service/frontend/src/api/stataService.ts`
  - Bundle / UploadSession / RefreshUploadUrls / FinalizeResult

## Decisions for v1 (recorded in spec)
- Duplicate filenames: allowed; disambiguate by server-generated `file_id` (no auto-rename).
- Presigned URLs: expire in <= 15 minutes; multipart sessions support refresh endpoint.
- Finalize: strong idempotency; materialize into job workspace `inputs/` and update manifest + fingerprint.

