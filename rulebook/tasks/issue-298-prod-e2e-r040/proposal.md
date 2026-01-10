# Proposal: issue-298-prod-e2e-r040

## Summary

Add a strict production readiness gate:
- Define a single production mode switch in `src/config.py` (`SS_ENV=production`).
- Make `/health/ready` report not-ready in production when critical dependencies are missing or configured as stub/fake.

## Context

- Task card: `openspec/specs/ss-production-e2e-audit-remediation/task_cards/round-01-prod-a__PROD-E2E-R040.md`
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md` (PROD-E2E-F004 / PROD-E2E-R040)
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F004)

## Impact

- Prevents deploying a “healthy” service that is actually running with stub/fake dependencies.
- Keeps non-production environments (tests/dev) unblocked by external dependency requirements.

