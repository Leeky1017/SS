# Proposal: issue-352-prod-e2e-r090

## Why
- All P0 remediation cards for the production E2E audit have landed; we must re-run the full production E2E audit journey and produce an auditable `READY` verdict.

## What Changes
- Execute the full `/v1` journey: redeem → inputs → draft preview → plan freeze → run → artifacts (+ restart + recover).
- Capture evidence (commands, HTTP request/response key fields, downloaded artifacts, restart recovery) in `openspec/_ops/task_runs/ISSUE-352.md`.
- Produce a go/no-go report with `READY` and an empty blockers list.

## Impact
- Affected spec pack (execution only):
  - `openspec/specs/ss-production-e2e-audit/spec.md`
  - `openspec/specs/ss-production-e2e-audit/task_cards/*`
- Affected remediation task card:
  - `openspec/specs/ss-production-e2e-audit-remediation/task_cards/round-01-prod-a__PROD-E2E-R090.md`
