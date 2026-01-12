# Proposal: issue-371-deploy-ready-r003

## Why
SS needs a production-ready Docker deployment baseline, but current repository assets (Dockerfile/compose) and Stata provisioning strategy have gaps. This task audits the current state against `ss-deployment-docker-readiness` and produces an actionable gap list + minimal remediation path.

## What Changes
- Audit current Docker/compose assets and runtime entrypoints (API/worker/Stata).
- Produce a numbered gap list (by requirement) with priority and mapped remediation cards.
- Define the minimal compose topology (MinIO + ss-api + ss-worker) and key volumes.
- Document Stata provisioning decision points/risks and recommend the lowest-risk default path.
- Update task card metadata and add run log evidence.

## Impact
- Affected specs:
  - `openspec/specs/ss-deployment-docker-readiness/spec.md`
  - `openspec/specs/ss-deployment-docker-minio/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
- Affected code: none (audit-only)
- Breaking change: NO
- User benefit: a production-oriented Docker readiness gap list with a minimal, sequenced remediation plan.
