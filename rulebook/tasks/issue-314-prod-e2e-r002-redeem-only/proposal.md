# Proposal: issue-314-prod-e2e-r002-redeem-only

## Why
- Production must have a single authoritative v1 job creation chain; legacy `POST /v1/jobs` bypasses the audited redeem→token flow (Finding F006).

## What Changes
- Remove legacy `POST /v1/jobs` endpoint from `src/api/jobs.py` and delete its compatibility toggle `v1_enable_legacy_post_jobs`.
- Update all tests/scripts/docs that call legacy job creation to use `POST /v1/task-codes/redeem`.

## Impact
- Affected specs:
  - `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Affected task card:
  - `openspec/specs/ss-production-e2e-audit-remediation/task_cards/round-01-prod-a__PROD-E2E-R002.md`
- Affected code:
  - `src/api/jobs.py`
  - `src/config.py`
  - any legacy-caller tests/scripts/docs
- Breaking change: YES (removes legacy job creation endpoint; clients must redeem task-codes instead)

