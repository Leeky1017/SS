# Spec: Multi-tenant support (Issue #121)

## Requirements

### R1: Tenant identity is explicit in request context

- Tenant identity MUST be determined from HTTP request context.
- The API MUST accept tenant identity via header `X-SS-Tenant-ID`.
- When the header is missing, the tenant MUST default to `default` for backward compatibility.
- Tenant id MUST be validated as a safe path segment (no traversal / separators).

### R2: Persistence is tenant-isolated

- Storage paths MUST be tenant-isolated so two tenants can have the same `job_id` without collisions.
- Tenant A MUST NOT be able to load or mutate tenant B’s job data via API calls.

### R3: Execution is tenant-isolated

- Queue claims MUST carry `tenant_id` so workers can resolve the correct storage location.

## Compatibility / migration

- Existing single-tenant deployments operate as tenant `default`.
- Tenant `default` MUST continue to use the existing on-disk layout under `jobs_dir`.
- Non-default tenants MUST store under `jobs_dir/tenants/<tenant_id>/...`.

## Scenarios

### S1: Same `job_id` across tenants is isolated

- GIVEN tenant `a` and tenant `b`
- WHEN both create a job with the same `job_id`
- THEN persisted data is stored under distinct tenant roots and does not collide

### S2: Cross-tenant access is rejected

- GIVEN tenant `a` created `job_id = X`
- WHEN tenant `b` requests `GET /jobs/X`
- THEN the API behaves as if the job does not exist for tenant `b`
