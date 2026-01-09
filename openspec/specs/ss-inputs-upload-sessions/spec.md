# Spec: ss-inputs-upload-sessions

## Purpose

Define a v1 large-file/high-concurrency inputs upload system for SS that avoids routing file bytes through the API server, while preserving the existing SS contracts:
- job workspace `inputs/` persistence
- `inputs/manifest.json` (schema_version=2, datasets list)
- `job.json.inputs.manifest_rel_path` + `job.json.inputs.fingerprint`
- `GET /v1/jobs/{job_id}/inputs/preview` semantics

The system uses a three-step flow:
1) declare a bundle of input files
2) create upload sessions (direct or multipart) with presigned URLs
3) finalize uploads to materialize them into the SS inputs subsystem

## Related specs (normative)

- Constitutional constraints: `openspec/specs/ss-constitution/spec.md`
- API surface and versioning: `openspec/specs/ss-api-surface/spec.md`
- Job contract and workspace path safety: `openspec/specs/ss-job-contract/spec.md`
- Security red lines: `openspec/specs/ss-security/spec.md`
- UX loop closure (inputs/preview): `openspec/specs/ss-ux-loop-closure/spec.md`
- Frontend entrypoint: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Multi-tenant header and isolation: `openspec/specs/ss-multi-tenant/spec.md`

## Semantic references (non-normative)

- Legacy field shapes: `legacy/stata_service/frontend/src/api/stataService.ts` (Bundle / UploadSession / RefreshUploadUrls / FinalizeResult)

## Vocabulary (v1)

- **Bundle**: a job-scoped declaration of one or more input files to be uploaded.
- **Bundle file**: one declared file inside a bundle, identified by `file_id`.
- **Upload session**: a server-issued upload authorization for exactly one bundle file, returning presigned URL(s).
- **Upload strategy**:
  - `direct`: one presigned PUT URL for the whole object
  - `multipart`: presigned PUT URLs per part, plus a fixed `part_size`
- **Finalize**: a server operation that (a) completes multipart assembly if needed, (b) verifies and fingerprints bytes, and (c) materializes the file into the SS inputs system (`inputs/manifest.json` + `job.json.inputs.*`).

## Requirements

### Requirement: Bundle endpoints define file roles and duplicate filename semantics

SS MUST expose job-scoped bundle endpoints under `/v1`:
- `POST /v1/jobs/{job_id}/inputs/bundle`
- `GET /v1/jobs/{job_id}/inputs/bundle`

`POST /v1/jobs/{job_id}/inputs/bundle` request body MUST be JSON and MUST include:
- `files[]` where each item includes:
  - `filename` (string)
  - `size_bytes` (int)
  - `role` (string enum; see below)
  - `mime_type` (string, optional)

`GET /v1/jobs/{job_id}/inputs/bundle` response body MUST include:
- `bundle_id` (string)
- `job_id` (string)
- `files[]` where each item includes:
  - `file_id` (string)
  - `filename` (string)
  - `size_bytes` (int)
  - `role` (string enum; see below)
  - `mime_type` (string | null)

Bundle file roles MUST be an explicit enum (v1):
- `primary_dataset`
- `secondary_dataset`
- `auxiliary_data` (appendix-like datasets)
- `other` (non-dataset inputs; stored but not used by `inputs/preview`)

Bundle validation MUST ensure exactly one `primary_dataset` is present in `files[]`.

Duplicate `filename` values within one bundle MUST be allowed and MUST be disambiguated by a server-generated `file_id` per bundle file (no auto-rename and no rejection due to duplicates).

#### Scenario: Creating a bundle yields stable file ids
- **WHEN** a client calls `POST /v1/jobs/{job_id}/inputs/bundle` with multiple files (including duplicate `filename`)
- **THEN** SS returns a bundle containing one `file_id` per file and preserves the original `filename` values as declared

### Requirement: Bundle file declaration is validated and path-safe

SS MUST treat each declared `filename` as untrusted input:
- it MUST be validated as a single safe path segment (no `..`, no separators, no absolute paths)
- for v1, the extension MUST be used to determine `format` (`csv` / `excel` / `dta`) for all bundle files (including `other`)
- SS MUST reject unsupported formats with a structured error

#### Scenario: Unsafe bundle filenames are rejected
- **WHEN** a client declares a bundle file with an unsafe `filename` such as `../data.csv`
- **THEN** SS rejects the request with a structured error and does not create/update the bundle

### Requirement: Upload session creation supports direct and multipart presigned URLs

SS MUST expose:
- `POST /v1/jobs/{job_id}/inputs/upload-sessions`

The request MUST include:
- `bundle_id` (string)
- `file_id` (string)

The response MUST include:
- `upload_session_id` (string)
- `job_id` (string)
- `file_id` (string)
- `upload_strategy` (`direct` | `multipart`)
- `expires_at` (ISO8601 string)

For `direct` sessions, the response MUST include:
- `presigned_url` (string)

For `multipart` sessions, the response MUST include:
- `part_size` (int, bytes)
- `presigned_urls[]` where each item includes:
  - `part_number` (int, starts at 1)
  - `url` (string)

Strategy selection MUST be server-controlled using config:
- `SS_UPLOAD_MULTIPART_THRESHOLD_BYTES`

#### Scenario: A small file receives a direct upload session
- **WHEN** a client requests an upload session for a bundle file below `SS_UPLOAD_MULTIPART_THRESHOLD_BYTES`
- **THEN** SS returns `upload_strategy=direct` and a single `presigned_url`

#### Scenario: A large file receives a multipart upload session
- **WHEN** a client requests an upload session for a bundle file at or above `SS_UPLOAD_MULTIPART_THRESHOLD_BYTES`
- **THEN** SS returns `upload_strategy=multipart` with `part_size` and `presigned_urls[]`

### Requirement: Presigned URL expiry is bounded and multipart refresh is supported

All presigned URLs MUST expire within 15 minutes, enforced by config:
- `SS_UPLOAD_PRESIGNED_URL_TTL_SECONDS` (default 900, max 900)

SS MUST expose a refresh endpoint for multipart sessions:
- `POST /v1/upload-sessions/{upload_session_id}/refresh-urls`

The refresh request MAY include:
- `part_numbers` (list[int]) to refresh only a subset; when omitted, refresh all parts

The refresh response MUST include:
- `upload_session_id` (string)
- `parts[]` where each item includes:
  - `part_number` (int)
  - `url` (string)
- `expires_at` (ISO8601 string)

#### Scenario: A client refreshes multipart upload URLs near expiry
- **WHEN** a client calls `POST /v1/upload-sessions/{upload_session_id}/refresh-urls` with `part_numbers`
- **THEN** SS returns new presigned URLs for the requested parts and a new `expires_at`

### Requirement: Finalize is strongly idempotent, retryable, and concurrency-safe

SS MUST expose:
- `POST /v1/upload-sessions/{upload_session_id}/finalize`

Finalize MUST be strongly idempotent by `upload_session_id`:
- repeated requests (including concurrent requests) MUST NOT create duplicate inputs or corrupt `inputs/manifest.json`
- once finalized successfully, subsequent finalize calls MUST return the same success payload

Finalize request body MUST be:
- `parts[]` where each item includes:
  - `part_number` (int)
  - `etag` (string)
  - `sha256` (string, optional; hex)

Finalize response MUST be a tagged union:
- success:
  - `success: true`
  - `status` (string)
  - `upload_session_id` (string)
  - `file_id` (string)
  - `sha256` (string)
  - `size_bytes` (int)
- failure:
  - `success: false`
  - `retryable` (bool)
  - `error_code` (string)
  - `message` (string)

#### Scenario: Concurrent finalize calls are safe
- **WHEN** two clients call finalize for the same `upload_session_id` concurrently
- **THEN** SS finalizes at most once and both calls return a consistent success payload (or a consistent failure payload)

### Requirement: Finalize materializes files into SS inputs and updates manifest + fingerprint

On successful finalize, SS MUST incorporate the uploaded file into the existing SS inputs system:
- Persist bytes under the job workspace `inputs/` using a server-generated safe `rel_path` (do not use the user-provided `filename` as a path).
- Write/update `inputs/manifest.json` using schema_version=2 and `datasets[]`.
- Update `job.json.inputs.manifest_rel_path` to `inputs/manifest.json`.
- Update `job.json.inputs.fingerprint` to a bundle-level deterministic fingerprint derived from the finalized files.

`inputs/manifest.json` schema_version=2 (v1 minimum fields):
- `schema_version`: `2`
- `datasets[]` items:
  - `dataset_key` (string)
  - `role` (string enum from the bundle role set)
  - `rel_path` (string, job-relative, under `inputs/`)
  - `original_name` (string)
  - `size_bytes` (int)
  - `sha256` (string, hex)
  - `fingerprint` (string, prefixed with `sha256:`)
  - `format` (`csv` | `excel` | `dta`)
  - `uploaded_at` (ISO8601 string)
  - `content_type` (string | null)

`dataset_key` generation MUST be deterministic:
- `dataset_key = "ds_" + sha256[:16]`

`job.json.inputs.fingerprint` MUST be computed as:
- build a canonical JSON list of `{sha256, size_bytes, role}` for every dataset in `datasets[]`
- sort the list by `(role, sha256)`
- JSON-encode with stable key ordering
- compute `sha256` over the UTF-8 bytes of that JSON
- prefix with `sha256:`

SS MUST index the persisted inputs as first-class artifacts:
- `inputs/manifest.json` (kind aligned with `ss-job-contract`)
- each dataset `rel_path` under `inputs/` (kind aligned with `ss-job-contract`)

#### Scenario: Finalize makes inputs preview-compatible
- **WHEN** a primary dataset upload session is finalized successfully
- **THEN** `GET /v1/jobs/{job_id}/inputs/preview` reads the persisted `inputs/manifest.json` primary dataset entry and returns a bounded preview

### Requirement: Upload endpoints require token authentication and do not expose object keys

All bundle/upload-session/finalize endpoints MUST require an auth token:
- `Authorization: Bearer ...`
- without a valid token, SS MUST reject the request and MUST NOT issue presigned URLs nor finalize uploads

Tenant identity MUST be handled per `ss-multi-tenant` and MUST NOT be bypassable by tokens:
- requests MAY include `X-SS-Tenant-ID` (default tenant allowed)
- a token MUST be bound to a single tenant/job scope, and MUST NOT authorize cross-tenant access

For security:
- SS MUST NOT allow clients to choose object store keys/paths.
- Object keys MUST be server-generated and tenant-isolated.
- Logs and artifacts MUST NOT leak bearer tokens (per `ss-security`).

Limits MUST be enforced via config items (names fixed by this spec):
- `SS_UPLOAD_MAX_FILE_SIZE_BYTES`
- `SS_UPLOAD_MAX_SESSIONS_PER_JOB`
- `SS_UPLOAD_MULTIPART_MIN_PART_SIZE_BYTES`
- `SS_UPLOAD_MULTIPART_MAX_PART_SIZE_BYTES`
- `SS_UPLOAD_MULTIPART_MAX_PARTS`
- `SS_UPLOAD_MULTIPART_THRESHOLD_BYTES`
- `SS_UPLOAD_PRESIGNED_URL_TTL_SECONDS`

#### Scenario: Missing token blocks upload session creation
- **WHEN** a client calls `POST /v1/jobs/{job_id}/inputs/upload-sessions` without `Authorization`
- **THEN** SS rejects the request and does not create an upload session

### Requirement: Observability and pressure-testing gates are defined

Implementations of this spec MUST provide evidence for concurrency behavior:
- session creation concurrency (many `POST /inputs/upload-sessions` in parallel)
- finalize concurrency (many `POST /upload-sessions/{id}/finalize` in parallel)

CI does not need to upload large files, but pytest MUST be able to cover concurrency logic using a fake object store adapter and anyio concurrency.

Evidence MUST be recorded in `openspec/_ops/task_runs/ISSUE-N.md`.

#### Scenario: Concurrency evidence is auditable
- **WHEN** a PR implements any upload-sessions capability from this spec
- **THEN** it includes pytest coverage for concurrency logic and records key commands/output in `openspec/_ops/task_runs/ISSUE-N.md`
