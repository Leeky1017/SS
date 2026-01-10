# Proposal: issue-333-prod-e2e-r012

## Why
Production E2E audit (F002) requires `plan/freeze` to emit an explicit, auditable execution contract (params/deps/outputs). Today `plan.json` lacks these fields, so operators cannot preflight dependencies, diagnose missing bindings, or audit expected outputs.

## What Changes
- Extend `POST /v1/jobs/{job_id}/plan/freeze` to extract `dependencies` and `outputs` from the selected template `meta.json`, and to compute a parameter binding contract (required/optional + bound values + missing list).
- Persist the contract into `artifacts/plan.json` and return the same contract fields in the API response.
- Add unit tests for missing/corrupt template meta error paths (structured error with context).

## Impact
- Affected specs: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Affected code: `src/domain/plan_service.py`, `src/api/**`, `src/domain/do_template_*`
- Breaking change: NO (additive fields and stricter validation on bad template meta)
- User benefit: Plan artifacts become an executable contract for preflight and auditing.
