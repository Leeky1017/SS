# Proposal: issue-433-admin-console

## Summary

Add a first-party SS admin console (backend + UI) for operational tasks: admin authentication, admin token management, Task Code issuance and lifecycle, job monitoring, and basic system status.

## Scope

ADDED:
- `/api/admin/*` API surface with independent admin auth.
- File-backed admin token store and Task Code store.
- Admin job listing/details, retry, and artifact download.
- System status endpoint (health + queue depth + worker status best-effort).
- Frontend admin UI served at `/admin`.

MODIFIED:
- Frontend build to produce a separate `/admin/` entry.
- Task code redemption flow to mark issued codes as used.

## Non-goals

- Fine-grained RBAC / multi-role permissions.
- External IdP (OIDC/SAML) integration.
- Full tenant provisioning automation beyond listing/selecting tenants.

