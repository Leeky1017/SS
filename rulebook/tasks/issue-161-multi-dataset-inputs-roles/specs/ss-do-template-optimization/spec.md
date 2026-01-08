# Delta Spec: ss-do-template-optimization (issue-161-multi-dataset-inputs-roles)

## Purpose

Define the delta requirements for multi-dataset job inputs (manifest + roles) to support Phase 3 composition work.

## Requirements

### Requirement: Multi-dataset upload persists roles and keys

SS MUST support uploading 2+ dataset files per job and MUST persist an inputs manifest that records each dataset with:
`dataset_key`, `role`, `rel_path`, and `fingerprint`.

#### Scenario: Uploading two datasets writes a multi-dataset manifest
- **GIVEN** a job exists
- **WHEN** a client uploads two dataset files for a job with roles `primary_dataset` and `secondary_dataset`
- **THEN** SS writes `inputs/manifest.json` with both datasets recorded as first-class entries
- **AND** `job.json.inputs.manifest_rel_path` points to `inputs/manifest.json`

### Requirement: Inputs fingerprint is deterministic across ordering

SS MUST compute `job.json.inputs.fingerprint` deterministically across all datasets and MUST NOT depend on upload ordering.

#### Scenario: Upload ordering does not change fingerprint
- **GIVEN** a job exists
- **WHEN** the same set of datasets is uploaded in different orders
- **THEN** `job.json.inputs.fingerprint` remains identical

### Requirement: Single-file upload remains supported

SS MUST remain backward compatible with the existing single-file upload path and MUST default the role to `primary_dataset`.

#### Scenario: Uploading one dataset defaults to primary role
- **GIVEN** a job exists
- **WHEN** a client uploads a single dataset file without specifying a role
- **THEN** SS stores the dataset with role `primary_dataset` and returns a successful upload response
