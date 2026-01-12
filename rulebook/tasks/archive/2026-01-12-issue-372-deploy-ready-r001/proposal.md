# Proposal: issue-372-deploy-ready-r001

## Why
Production deployment needs predictable, reviewable do-template behavior, but the library’s real coverage for wide/long/panel data is currently implicit. Without an auditable capability matrix, shape mismatches are only discovered at runtime, creating non-deterministic production failures.

## What Changes
- Add an auditable wide/long/panel capability matrix report grounded in `assets/stata_do_library/do/` + `do/meta/*.meta.json`.
- Record per-conclusion template evidence pointers (template id + code locations) and map gaps to remediation card DEPLOY-READY-R030.
- Record key commands/outputs in `openspec/_ops/task_runs/ISSUE-372.md`.

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-readiness/` (audit evidence only; no normative change)
- Affected code: `assets/stata_do_library/` (read-only audit), `rulebook/tasks/.../evidence/`, `openspec/_ops/task_runs/`
- Breaking change: NO
- User benefit: Clear wide/long/panel fit + risks, enabling deployment readiness reviews and follow-up remediation planning.
