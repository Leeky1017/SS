# Proposal: issue-389-deploy-ready-r020

## Why
Production Docker builds need a reproducible dependency input; `pyproject.toml` currently uses loose constraints (`>=`) which are not sufficient for repeatable builds and rollbacks.

## What Changes
- Add a pinned, repo-root `requirements.txt` exported from `pyproject.toml`.
- Document the generation command + update strategy.
- Ensure Docker-related assets install via `requirements.txt` (or document pending Dockerfile wiring).

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Affected code: `requirements.txt` and Docker build assets
- Breaking change: NO
- User benefit: reproducible production dependency installs and easier rollbacks
