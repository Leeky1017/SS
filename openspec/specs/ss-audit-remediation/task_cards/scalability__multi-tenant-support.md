# Scalability: Multi-tenant support (tenant isolation)

## Background

The audit identified that the current architecture is single-tenant and lacks explicit tenant isolation boundaries, which limits safe shared deployments.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏多租户支持”
- `Audit/03_Integrated_Action_Plan.md` → “任务 3.2：多租户支持”

## Goal

Define and implement a multi-tenant strategy that isolates persistence and execution, and that can be introduced without breaking existing single-tenant deployments.

## Dependencies & parallelism

- Hard dependencies: `scalability__job-store-sharding.md` (tenant isolation impacts storage layout)
- Parallelizable with: ops track tasks

## Acceptance checklist

- [x] Define the tenant model and required request context (how tenant identity is determined)
- [x] Persistence is tenant-isolated and prevents collisions (including same `job_id` across tenants)
- [x] Document the migration/compatibility plan for existing single-tenant deployments
- [x] Tests cover at least one isolation invariant (no cross-tenant access)
- [x] Implementation run log records `ruff check .`, `pytest -q`, and deployment notes

## Estimate

- 12-16h

## Completion

- PR: https://github.com/Leeky1017/SS/pull/122
- Notes:
  - Tenant identity comes from `X-SS-Tenant-ID` (defaults to `default`)
  - JobStore and worker queue are tenant-isolated; same `job_id` across tenants no longer collides
  - Added isolation tests (no cross-tenant access; same job_id across tenants)
- Run log: `openspec/_ops/task_runs/ISSUE-121.md`
