# Spec: ss-deployment-docker-minio

## Purpose

Define a production-compatible Docker deployment recipe for SS v1 upload sessions using a real S3-compatible object store (MinIO), while preserving the contract that upload bytes do not flow through the SS API server (direct/multipart presign + finalize).

## Related specs (normative)

- Constitutional constraints: `openspec/specs/ss-constitution/spec.md`
- Upload sessions v1 contract: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Delivery workflow gates: `openspec/specs/ss-delivery-workflow/spec.md`

## Requirements

### Requirement: Production MUST use a real S3-compatible backend (no runtime fake)

In production, SS MUST use the runtime object store backend:
- `SS_UPLOAD_OBJECT_STORE_BACKEND=s3`

MinIO (or other S3-compatible implementations like Ceph RGW) qualifies as a real production backend and satisfies the “no runtime fake backend” remediation intent.

Verification:
- Confirm `SS_UPLOAD_OBJECT_STORE_BACKEND` is `s3`.
- Confirm MinIO is an independent service (not embedded in the SS process).

#### Scenario: Production startup fails when required S3 config is missing
- **WHEN** `SS_ENV=production` and any of `SS_UPLOAD_S3_BUCKET`, `SS_UPLOAD_S3_ACCESS_KEY_ID`, `SS_UPLOAD_S3_SECRET_ACCESS_KEY` is missing/empty
- **THEN** startup fails with a stable error code `OBJECT_STORE_CONFIG_INVALID` (log event `SS_PRODUCTION_GATE_UPLOAD_OBJECT_STORE_INVALID`)

### Requirement: Upload deployment MUST use config keys from `src/config.py`

Deployments MUST configure upload sessions using these fixed env keys (loaded only via `src/config.py`):
- Backend selection:
  - `SS_UPLOAD_OBJECT_STORE_BACKEND` (must be `s3` in production)
- S3/S3-compatible connection:
  - `SS_UPLOAD_S3_ENDPOINT` (S3-compatible endpoint URL; required for MinIO)
  - `SS_UPLOAD_S3_REGION` (recommended for MinIO: `us-east-1`)
  - `SS_UPLOAD_S3_BUCKET`
  - `SS_UPLOAD_S3_ACCESS_KEY_ID`
  - `SS_UPLOAD_S3_SECRET_ACCESS_KEY`
- Presign and upload limits:
  - `SS_UPLOAD_PRESIGNED_URL_TTL_SECONDS` (default `900`, max `900`)
  - `SS_UPLOAD_MAX_FILE_SIZE_BYTES`
  - `SS_UPLOAD_MAX_SESSIONS_PER_JOB`
  - `SS_UPLOAD_MULTIPART_THRESHOLD_BYTES`
  - `SS_UPLOAD_MULTIPART_MIN_PART_SIZE_BYTES`
  - `SS_UPLOAD_MULTIPART_PART_SIZE_BYTES`
  - `SS_UPLOAD_MULTIPART_MAX_PART_SIZE_BYTES`
  - `SS_UPLOAD_MULTIPART_MAX_PARTS`
  - `SS_UPLOAD_MAX_BUNDLE_FILES`

Verification:
- Inspect `src/config.py` for the canonical env keys and defaults.

#### Scenario: A deployment references only canonical upload env keys
- **WHEN** a Docker deployment recipe for upload sessions is reviewed
- **THEN** it references only the env keys above (no ad-hoc keys and no runtime fake backend)

### Requirement: Presigned URL host MUST be client-reachable and MUST match the signing endpoint

SS generates presigned URLs using the configured `SS_UPLOAD_S3_ENDPOINT`. Deployments MUST ensure:
- The presigned URL host is reachable by the uploading client.
- The client uses exactly the presigned URL as returned (no host rewriting via proxying).
- `SS_UPLOAD_S3_ENDPOINT` is the same endpoint used for signing and for SS-side S3 API calls (multipart create/complete/abort, head/get).

Deployments MUST NOT use “internal endpoint for signing + external endpoint for clients”, because host mismatches break S3v4 signatures.

Verification:
- In `POST /v1/jobs/{job_id}/inputs/upload-sessions`, confirm returned `presigned_url`/`url` hosts are reachable from the client.
- Confirm clients can `PUT` to the returned URL without rewriting `Host`.

#### Scenario: A presigned URL is usable by the client without host rewriting
- **WHEN** SS returns a presigned URL using `SS_UPLOAD_S3_ENDPOINT`
- **THEN** the client can `PUT` to that URL successfully without rewriting the URL host

### Requirement: Docker + MinIO direct upload session MUST work end-to-end

With Docker-deployed SS and MinIO, a direct upload session MUST support:
- create bundle
- create upload session (`upload_strategy=direct`)
- client `PUT` to the presigned URL
- finalize
- existing inputs semantics are preserved (manifest + preview)

Verification (example commands; tenant header optional):
- Start SS + MinIO using a recipe that sets `SS_UPLOAD_S3_ENDPOINT` to a client-reachable host.
- Create a bundle: `POST /v1/jobs/{job_id}/inputs/bundle`.
- Create a session: `POST /v1/jobs/{job_id}/inputs/upload-sessions`.
- Upload via presign: `curl -X PUT --data-binary @"$FILE_PATH" "$PRESIGNED_URL"`.
- Finalize: `POST /v1/upload-sessions/{upload_session_id}/finalize`.
- Validate: `GET /v1/jobs/{job_id}/inputs/preview` returns rows and `GET /v1/jobs/{job_id}` includes `job.inputs.manifest_rel_path`.

#### Scenario: Docker + MinIO direct upload session works end-to-end
- **WHEN** a client uploads a small file through a direct presigned URL and calls finalize
- **THEN** finalize succeeds and `inputs/preview` reflects the uploaded primary dataset

### Requirement: Docker + MinIO multipart upload session MUST work end-to-end (refresh + finalize)

With Docker-deployed SS and MinIO, a multipart upload session MUST support:
- create upload session (`upload_strategy=multipart`)
- refresh URLs (`/refresh-urls`) for all or a subset of parts
- client `PUT` each part via its presigned URL and capture `ETag`
- finalize with `parts[]` containing `{part_number, etag}`
- existing inputs semantics are preserved (manifest + preview)

Verification tips:
- For manual validation, set `SS_UPLOAD_MULTIPART_THRESHOLD_BYTES=1` to force multipart issuance, and keep the test file small.
- Capture each part upload `ETag` response header and pass it back to finalize.

#### Scenario: Docker + MinIO multipart upload session works end-to-end
- **WHEN** a client uploads all multipart parts via presigned URLs (using refreshed URLs if needed) and calls finalize
- **THEN** finalize succeeds and `inputs/preview` reflects the uploaded primary dataset

## Verification assets

- End-to-end self-check script (direct + multipart, includes multipart `ETag` capture and `finalize` parts payload):
  - `openspec/specs/ss-deployment-docker-minio/assets/uploads_e2e_selfcheck.sh`
