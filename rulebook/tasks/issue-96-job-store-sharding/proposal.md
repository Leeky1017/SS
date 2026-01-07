# Proposal: issue-96-job-store-sharding

## Summary

Introduce a sharded job workspace directory layout to avoid single-directory filesystem limits and performance degradation at high job counts, while remaining backward compatible with legacy `jobs/<job_id>/...` jobs.

## Scope

ADDED:
- Shard function and path resolver for job workspace directories.

MODIFIED:
- File job store path resolution (sharded + legacy).
- Job workspace path resolution for runs, artifacts, and LLM tracing.
- Job contract docs to define the sharded layout and migration strategy.

## Non-goals

- New storage backends (e.g., S3/Redis) — handled by separate scalability tasks.
- Bulk migration tooling beyond a documented operational procedure.

