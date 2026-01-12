# Proposal: issue-365-deploy-docker-readiness

## Why
SS needs a production-ready Docker deployment path on remote servers. Today the repo lacks a clear, validated “Docker readiness” spec and a staged audit/remediation plan (API + Worker + MinIO + Stata strategy + input/output capabilities).

## What Changes
- Add a new OpenSpec `ss-deployment-docker-readiness` defining end-to-end requirements + acceptance criteria for Docker-based deployment readiness.
- Add task cards for audit (do-template capabilities, compose gap) and remediation (Dockerfile, compose worker, Stata strategy, dependency lock) and a final e2e deployment gate.

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-readiness/spec.md` (new)
- Affected code: none (spec + task cards only)
- Breaking change: NO
- User benefit: a single, enforceable source of truth for Docker deployment readiness and a phased execution plan for closing gaps.
