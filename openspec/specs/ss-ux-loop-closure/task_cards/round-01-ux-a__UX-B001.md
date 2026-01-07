# [ROUND-01-UX-A] UX-B001: 数据上传 + 数据预览（CSV/Excel/DTA）

## Metadata

- Priority: P0 (Blocker)
- Issue: #126 https://github.com/Leeky1017/SS/issues/126
- Audit: #124 https://github.com/Leeky1017/SS/issues/124
- Spec: `openspec/specs/ss-ux-loop-closure/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-testing-strategy/README.md`（场景 A）

## Problem (from audit)

Audit verdict states the UX loop cannot be completed because SS has no API to:
- upload a dataset file for a job
- parse/preview it for column recognition
- produce an inputs manifest + fingerprint required for deterministic execution planning

Evidence: `Audit/04_Production_Readiness_UX_Audit.md`

## Goal

Provide a **job-scoped** dataset input capability so a user can:
1) upload a primary dataset file (CSV/Excel/DTA)
2) preview columns + sample rows
3) persist an inputs manifest and fingerprint in `job.json` for downstream plan/runner usage

## Scope (v1)

### API surface (v1)

SS SHOULD expose job-scoped endpoints (names are suggestions; final paths must remain under `/v1`):

- Upload
  - `POST /v1/jobs/{job_id}/inputs/upload`
  - Content-Type: `multipart/form-data`
  - Fields:
    - `file`: required
    - `role`: optional; default `primary_dataset` (reserved for future multiple inputs)
    - `filename`: optional override (server MUST sanitize)

- Preview
  - `GET /v1/jobs/{job_id}/inputs/preview?rows=<N>&columns=<M>`
  - Returns a preview derived from the persisted primary dataset

### Storage contract (job workspace)

- The uploaded dataset MUST be persisted under job workspace `inputs/` with a **job-relative safe path**.
- SS MUST create an inputs manifest file and set:
  - `job.inputs.manifest_rel_path` to the manifest path (job-relative)
  - `job.inputs.fingerprint` to a stable fingerprint string

Recommended minimal layout (v1):
- `inputs/primary.<ext>` (actual stored dataset)
- `inputs/manifest.json` (inputs manifest)

### Inputs manifest format (v1, minimal)

The manifest MUST be JSON and MUST be stable enough for deterministic plan generation.

Recommended fields (v1):
- `schema_version`: int (start with `1`)
- `primary_dataset`:
  - `rel_path`: string (job-relative, safe)
  - `original_name`: string
  - `size_bytes`: int
  - `sha256`: string (hex)
  - `format`: string enum (`csv` / `excel` / `dta`)
  - `uploaded_at`: ISO8601 string
  - `content_type`: string | null

### Fingerprint (v1)

- `inputs.fingerprint` MUST be derived from the dataset content.
- Recommended: `sha256:<hex>` computed from file bytes.

### Preview semantics (v1)

Preview is **best-effort** and MUST be bounded:
- `rows` default 20, max 200
- response SHOULD include:
  - `columns[]`: name + inferred type (best-effort; unknown allowed)
  - `row_count`: best-effort; may be null for formats where counting is expensive
  - `sample_rows[]`: first N rows (string/number/bool/null only)

## Error handling (structured)

Upload/preview failures MUST return structured errors (align with `SSError` shape used elsewhere).

Recommended `error_code` set (v1):
- `INPUT_EMPTY_FILE`
- `INPUT_UNSUPPORTED_FORMAT`
- `INPUT_PARSE_FAILED`
- `INPUT_STORAGE_FAILED`
- `JOB_NOT_FOUND` (existing)
- `JOB_DATA_CORRUPTED` (existing)

## Security and tenancy constraints

- Tenant id MUST come from `X-SS-Tenant-ID` (default allowed) and MUST be path-safe.
- Uploaded filenames MUST be sanitized (no `..`, no absolute paths, no `~`, no backslashes).
- Persisted paths MUST be validated using job-relative safety rules (`ss-job-contract`).
- Preview MUST not execute arbitrary code and MUST not invoke Stata.

## Testing requirements

Tests MUST validate user-visible behavior (AAA style; no mocking internal modules except boundaries).

Minimum tests (suggested):
- Happy path: upload CSV → preview returns columns + sample rows
- Empty file → `INPUT_EMPTY_FILE`
- Unsupported extension → `INPUT_UNSUPPORTED_FORMAT`
- Malformed CSV → `INPUT_PARSE_FAILED`
- Multi-tenant safety: unsafe tenant id rejected (existing behavior)
- Path traversal: filename with `../` rejected (no write outside job)

## Acceptance checklist

- [x] API: dataset upload endpoint exists under `/v1` and persists under `inputs/`
- [x] API: dataset preview endpoint exists and returns bounded columns + sample rows
- [x] `job.json` updates `inputs.manifest_rel_path` and `inputs.fingerprint`
- [x] Errors are structured with stable `error_code` values
- [x] Tests cover happy path + key invalid inputs and path-safety

## Completion

- PR: https://github.com/Leeky1017/SS/pull/136
- Run log: `openspec/_ops/task_runs/ISSUE-126.md`
- Summary:
  - Implemented `/v1/jobs/{job_id}/inputs/upload` and `/v1/jobs/{job_id}/inputs/preview`
  - Persisted `inputs/manifest.json` + `sha256:<hex>` fingerprint into `job.json`
  - Added tests for happy path + key invalid inputs
