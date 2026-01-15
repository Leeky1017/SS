# ISSUE-475
- Issue: #475
- Branch: task/475-align-audit-r001
- PR: <fill-after-created>

## Plan
- Inventory backend endpoints
- Compare frontend/backend contracts
- Deliver audit report + evidence

## Runs
### 2026-01-15 11:47 openapi-export-attempt
- Command: `python3 -c "from src.main import app; print('openapi', app.openapi().get('openapi'))"`
- Key output: `ModuleNotFoundError: No module named 'fastapi'`
- Evidence: `Audit/api_contract_audit_report.md`

### 2026-01-15 11:47 endpoint-inventory
- Command: `rg -n "@router\\.(get|post|put|patch|delete)\\(" src/api | wc -l`
- Key output: `38`
- Evidence: `Audit/api_contract_audit_report.md`

### 2026-01-15 11:47 frontend-client-coverage
- Command: `rg -n "public async" frontend/src/api/client.ts | wc -l`
- Key output: `14`
- Evidence: `Audit/api_contract_audit_report.md`

### 2026-01-15 11:49 pr-preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`
- Evidence: `Audit/api_contract_audit_report.md`
