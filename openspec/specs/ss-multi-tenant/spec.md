# Spec: ss-multi-tenant

## Purpose

Define a multi-tenant strategy so multiple tenants can safely share one SS deployment without data collisions or cross-tenant access.

## Requirements

### Requirement: Tenant identity is explicit and validated

SS MUST determine tenant identity from request context via HTTP header `X-SS-Tenant-ID`, and MUST validate `tenant_id` as a safe path segment (no traversal and no path separators).

#### Scenario: Missing tenant header uses default tenant
- **WHEN** a request does not include `X-SS-Tenant-ID`
- **THEN** SS treats the request as tenant `default` for backward compatibility

### Requirement: Persistence is tenant-isolated

SS MUST scope persisted job data by `tenant_id` so two tenants can use the same `job_id` without collisions.

#### Scenario: Same job_id across tenants does not collide
- **WHEN** tenant `A` and tenant `B` both have a job with the same `job_id`
- **THEN** their persisted data is isolated and cannot collide

### Requirement: Execution is tenant-isolated

Queue claims MUST carry `tenant_id` so workers can resolve the correct job workspace and persist artifacts under the correct tenant root.

#### Scenario: Worker resolves job workspace using tenant_id
- **WHEN** a worker claims a job
- **THEN** the claim includes `tenant_id`, and the worker uses it to load and execute the job

### Requirement: Compatibility / migration plan is explicit

SS MUST support introducing multi-tenant support without breaking existing single-tenant deployments.

#### Scenario: Existing single-tenant deployments remain valid
- **WHEN** upgrading an existing deployment that previously did not send tenant identity
- **THEN** existing jobs remain loadable as tenant `default` without manual moves

## Notes

### Storage layout (file backend)

- Tenant `default`:
  - Existing layout under `jobs_dir`:
    - `jobs_dir/<shard>/<job_id>/...` (with legacy fallback `jobs_dir/<job_id>/...`)
- Non-default tenants:
  - `jobs_dir/tenants/<tenant_id>/<shard>/<job_id>/...`

### Queue layout (file backend)

- Tenant `default`:
  - `queue_dir/queued/<job_id>.json`
  - `queue_dir/claimed/<job_id>__<claim_id>.json`
- Non-default tenants:
  - `queue_dir/queued/<tenant_id>/<job_id>.json`
  - `queue_dir/claimed/<tenant_id>/<job_id>__<claim_id>.json`
