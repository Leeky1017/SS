# Proposal: issue-479-api-contract-sync

## Why
Issue #477 showed repeated contract drift risk: frontend TypeScript types were manually maintained and could
silently diverge from backend Pydantic/FastAPI schemas. This is a structural hazard that will regress unless
we add an automated, CI-enforced synchronization mechanism.

## What Changes
- Add a deterministic pipeline to export backend OpenAPI spec from the FastAPI app.
- Generate frontend TypeScript types from the exported OpenAPI (no manual edits).
- Add a CI guardrail that fails when generated types differ from committed types.
- Document “contract-first” workflow for agents: backend schema changes first, frontend types are generated.

## Impact
- Affected specs: `rulebook/tasks/issue-479-api-contract-sync/specs/ss-api-contract-sync/spec.md`
- Affected code: `scripts/`, `.github/workflows/ci.yml`, `frontend/src/api/types.ts`,
  `frontend/src/features/admin/adminApiTypes.ts`, `AGENTS.md`
- Breaking change: NO (types generation only; no API behavior changes)
- User benefit: Prevents future frontend/backend contract drift by making mismatch a CI failure.
