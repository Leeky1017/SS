# Spec: api-contract-audit (Issue #475)

## Goal

Produce a complete, structured audit report for SS API contracts covering:

- Backend: `src/api/schemas.py`, `src/api/admin/schemas.py`, and all router modules under `src/api/`
- Domain: `src/domain/models.py`, `src/domain/draft_v1_contract.py`
- Frontend: `frontend/src/api/types.ts`, `frontend/src/api/client.ts`, and `frontend/src/features/**`

## Requirements

1. The report MUST be saved at `Audit/api_contract_audit_report.md`.
2. The report MUST list every discovered backend endpoint (path + method), even if “no issues”.
3. For each mismatch, the report MUST include:
   - Description of the mismatch
   - Code references (file + line)
   - An executable fix plan (specific file paths + what to change)
4. The report MUST include an explicit “reverse validation” section that maps each public method in `frontend/src/api/client.ts` to a covered endpoint.
5. The audit MUST NOT modify any production code (audit-only deliverable).

## Scenarios

- When scanning `src/api/**` routes, then the report includes all discovered endpoints and a total count.
- When comparing each endpoint, then the report records “OK” or lists mismatches with fix plans.
- When traversing `frontend/src/api/client.ts`, then every method is covered by the report’s endpoint list.
