# Spec: ss-job-contract

## Purpose

Define SS job workspace layout, versioned `job.json` contract, and artifact indexing rules so runs are deterministic and auditable.

## Requirements

### Requirement: Job is persisted as a versioned job.json record

SS MUST persist each job as `jobs/<job_id>/job.json` and MUST include a `schema_version` field for forward-compatible migrations.

#### Scenario: Job contract doc exists
- **WHEN** browsing `openspec/specs/ss-job-contract/`
- **THEN** `README.md` describes the `job.json` v1 field semantics and workspace layout

### Requirement: Artifact paths are job-relative and safe

All artifact references MUST use a job-relative `rel_path` and MUST NOT allow absolute paths or `..` traversal outside the job directory.

#### Scenario: Artifact contract states path rules
- **WHEN** reading `openspec/specs/ss-job-contract/README.md`
- **THEN** it forbids absolute paths and traversal for artifact `rel_path`

### Requirement: Artifact kinds are enumerated

Artifacts MUST use an enumerated `kind` vocabulary (no ad-hoc free strings) so downstream code can reliably filter and render outputs.

#### Scenario: Artifact kind vocabulary is listed
- **WHEN** browsing `openspec/specs/ss-job-contract/README.md`
- **THEN** it lists recommended artifact kinds and examples
