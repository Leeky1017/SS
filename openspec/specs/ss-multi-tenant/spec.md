# Spec: ss-multi-tenant

## Purpose

Define a multi-tenant strategy so multiple tenants can safely share one SS deployment without data collisions or cross-tenant access.

## Tenant model

- A **tenant** is identified by `tenant_id` (string).
- Tenant identity is provided by HTTP header `X-SS-Tenant-ID`.
- If `X-SS-Tenant-ID` is missing, SS treats the request as tenant `default` for backward compatibility.
- `tenant_id` MUST be validated as a safe path segment (no traversal and no path separators).

## Isolation boundaries

### Persistence (job store)

- Job store paths MUST be tenant-scoped so two tenants can use the same `job_id` without collisions.
- On-disk layout:
  - Tenant `default`:
    - Job root uses the existing layout under `jobs_dir`:
      - `jobs_dir/<shard>/<job_id>/...` (with legacy fallback `jobs_dir/<job_id>/...`)
  - Non-default tenants:
    - `jobs_dir/tenants/<tenant_id>/<shard>/<job_id>/...`

### Execution (worker queue + runner)

- Queue claims MUST carry `tenant_id` so workers resolve the correct job workspace.
- On-disk layout (file-backed queue):
  - Tenant `default`:
    - `queue_dir/queued/<job_id>.json`
    - `queue_dir/claimed/<job_id>__<claim_id>.json`
  - Non-default tenants:
    - `queue_dir/queued/<tenant_id>/<job_id>.json`
    - `queue_dir/claimed/<tenant_id>/<job_id>__<claim_id>.json`

## Compatibility / migration

- Existing single-tenant deployments are treated as tenant `default` with no storage moves required.
- Multi-tenant can be introduced incrementally by sending `X-SS-Tenant-ID` on requests.

## Invariants

- Cross-tenant access is rejected: tenant A cannot read or mutate tenant B’s job data.
- Same `job_id` across tenants is supported without collisions.

