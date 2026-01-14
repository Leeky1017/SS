# Proposal: issue-471-start-ps1-launcher

## Why
Windows operators rely on `start.ps1` as the primary non-Docker entrypoint. The current script assumes an existing venv and can leave a worker process running after the API is stopped (Ctrl+C), which creates confusing local state and requires manual cleanup.

## What Changes
- Upgrade `start.ps1` into a reliable one-command launcher:
  - Best-effort `.env` loading (non-overriding)
  - Deterministic venv selection/creation (create when missing)
  - Optional dependency install controls (skip/force)
  - Start worker in background with logs
  - Stop worker automatically when API process exits (Ctrl+C)
- Update the Windows non-Docker deployment OpenSpec to describe expected launcher behavior.

## Impact
- Affected specs: `openspec/specs/ss-deployment-windows-non-docker/spec.md`
- Affected code: `start.ps1`
- Breaking change: NO
- User benefit: One command reliably starts SS on Windows and avoids orphaned worker processes.
