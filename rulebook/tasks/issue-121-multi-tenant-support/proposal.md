# Proposal: issue-121-multi-tenant-support

## Why
SS is currently effectively single-tenant: storage paths and queue records are keyed only by `job_id`, so multiple tenants cannot safely share one deployment without collisions or cross-tenant access risk.

## What Changes
- Define a tenant identity model and request context (`X-SS-Tenant-ID`, default `default`).
- Thread `tenant_id` through API → domain → infra boundaries (explicit parameters, no globals).
- Enforce tenant isolation in persistence (job store paths) and execution (queue claim + worker load path).
- Maintain backward compatibility for existing single-tenant deployments (default tenant keeps current layout).

## Impact
- Affected specs: `openspec/specs/ss-audit-remediation/task_cards/scalability__multi-tenant-support.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/`, `src/utils/`
- Breaking change: NO (default tenant preserves existing behavior)
- User benefit: Multiple tenants can safely share one SS deployment; same `job_id` across tenants no longer collides.
