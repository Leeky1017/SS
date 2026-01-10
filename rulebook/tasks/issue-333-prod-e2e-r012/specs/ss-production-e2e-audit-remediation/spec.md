# Spec Delta: PROD-E2E-R012 (issue-333-prod-e2e-r012)

Authoritative spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md` (F002).

## Requirement: Plan freeze emits an explicit contract (additive fields)

`POST /v1/jobs/{job_id}/plan/freeze` MUST return an explicit, auditable contract in both:
- response body, and
- `artifacts/plan.json`

The contract MUST include:
- `template_id` (from the persisted selection result)
- `params_contract`:
  - `required` / `optional` param identifiers derived from template meta
  - `bound_values` map (only for provided keys)
  - `missing_required` list (empty on success)
- `dependencies` sourced from template meta (`meta.dependencies`)
- `outputs_contract` sourced from template meta (`meta.outputs`) and constrained to archive-safe relative paths

## Scenario: Contract contains deps and outputs

- GIVEN a job with `selected_template_id` persisted by the selection step
- WHEN calling `POST /v1/jobs/{job_id}/plan/freeze`
- THEN the response and downloaded `artifacts/plan.json` include `template_id`, `params_contract`, `dependencies`, and `outputs_contract`

## Scenario: Missing or corrupt template meta fails with structured error

- GIVEN a job with a `selected_template_id` whose `meta.json` is missing or invalid JSON
- WHEN calling `POST /v1/jobs/{job_id}/plan/freeze`
- THEN the request fails with a structured error including:
  - an error code identifying the meta failure mode, and
  - context containing `job_id` and `template_id`

