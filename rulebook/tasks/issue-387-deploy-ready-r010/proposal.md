# Proposal: issue-387-deploy-ready-r010

## Why
SS needs a reproducible production image build entrypoint; without a repo-root Dockerfile, CI and operators cannot standardize builds or validate deployment workflows.

## What Changes
- Add a repository-root `Dockerfile` (based on `python:3.12-slim`) that can run either the API or the worker via different container commands.
- Add `.dockerignore` to keep Docker build contexts small and deterministic.
- Add a run log with build/start evidence.

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Affected code: `Dockerfile`, `.dockerignore`, `openspec/_ops/task_runs/ISSUE-387.md`
- Breaking change: NO
- User benefit: Operators can build one image (`ss:prod`) and run API/worker containers consistently.
