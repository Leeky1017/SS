# Proposal: issue-161-multi-dataset-inputs-roles

## Why
Phase 3 composition needs multiple datasets per job, but SS currently only supports uploading a single primary dataset.

## What Changes
- Extend the inputs upload API to accept multiple dataset files per job and store an explicit role per dataset.
- Persist datasets to `inputs/` and write an inputs manifest that records stable `dataset_key`, `role`, `rel_path`, and `fingerprint`.
- Update `job.json.inputs` to reference the manifest and compute a deterministic fingerprint across all datasets.
- Index uploaded datasets and the manifest in `job.artifacts_index` using enumerated artifact kinds.

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-3.1__multi-dataset-inputs-and-roles.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
- Affected code:
  - `src/api/jobs.py`, `src/api/schemas.py`
  - `src/domain/job_inputs_service.py`, `src/domain/do_file_generator.py`, `src/domain/models.py`
  - `tests/test_job_inputs_api.py`
- Breaking change: NO
- User benefit: users can upload 2+ datasets with explicit roles; downstream composition can reference datasets deterministically.
