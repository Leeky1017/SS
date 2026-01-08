# Phase 3.1: Multi-dataset Inputs + Roles

## Metadata

- Issue: #161
- Parent: #125
- Superphase: Phase 3 (adaptive composition)
- Related specs:
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Support uploading **2+ dataset files** per job, persist them as first-class job inputs (manifest + artifact index), and assign explicit roles:
`primary_dataset` / `secondary_dataset` / `auxiliary_data`.

## In scope

- API supports multi-file upload for datasets (>= 2).
- Job inputs manifest (`inputs/manifest.json`) records each dataset with:
  - stable `dataset_key`
  - `role`
  - `rel_path`
  - (recommended) `fingerprint`
- `job.json.inputs` points to the manifest and includes an input fingerprint stable across ordering.
- Artifacts index includes dataset input artifacts (kinds enumerated; no ad-hoc strings).
- Backward compatibility: single-file upload still works and defaults to `primary_dataset`.

## Out of scope

- Composition planning/routing (Phase 3.2).
- Composition execution modes (Phase 3.3).
- Executor-side inference of roles/relationships without explicit plan.

## Acceptance checklist

- [x] A job can be created with >= 2 uploaded dataset files
- [x] Inputs manifest is written and referenced from `job.json.inputs.manifest_rel_path`
- [x] Each dataset has an explicit role and stable key, and is indexed as an artifact
- [x] Input fingerprint covers all datasets deterministically
- [x] Tests cover multi-file upload + manifest validation + backward-compat single-file path

## Completion

- PR: https://github.com/Leeky1017/SS/pull/166
- Implemented multi-file inputs upload with explicit roles + deterministic fingerprint
- Persisted `inputs/manifest.json` as `datasets[]` with stable `dataset_key` + `rel_path` + `fingerprint`
- Added tests for multi-file upload + backward-compatible single-file path
- Run log: `openspec/_ops/task_runs/ISSUE-161.md`
