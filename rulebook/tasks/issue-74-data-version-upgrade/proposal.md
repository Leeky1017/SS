# Proposal: issue-74-data-version-upgrade

## Why
The audit identified a missing data migration/version upgrade strategy: persisted `job.json` is rejected when `schema_version` differs from the current constant, making any evolution a breaking change with no migration path.

## What Changes
- Define a schema versioning policy (current write version + supported read versions) in the job contract docs.
- Introduce explicit `job.json` migrations in `JobStore.load()` (v1 → v2) and persist the migrated payload.
- Emit a structured migration log event for observability and troubleshooting.
- Add tests covering a real migration path and an unsupported-version rejection path.

## Impact
- Affected specs: `openspec/specs/ss-job-contract/README.md`
- Affected code: `src/domain/models.py`, `src/domain/job_service.py`, `src/infra/job_store.py`, tests
- Breaking change: NO (read supports v1; write moves to v2)
- User benefit: persisted jobs remain loadable across schema evolution with explicit, test-covered migrations
