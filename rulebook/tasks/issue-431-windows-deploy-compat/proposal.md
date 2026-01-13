# Proposal: issue-431-windows-deploy-compat

## Why
Deploying SS on a Windows VPS (non-Docker) currently fails at startup due to Unix-only modules and missing `.env` loading, and users cannot access the UI at `http://<host>:8000/` because the frontend is not served.

## What Changes
- Add a cross-platform file locking helper and remove direct `fcntl` imports from infra stores.
- Load `.env` automatically at process start so `src/config.py` sees required environment variables on Windows.
- Serve `frontend/dist` from FastAPI at `/` so the UI is accessible without a separate frontend server.
- Add a one-click `start.ps1` script to load `.env` and start API + worker.

## Impact
- Affected specs: `openspec/specs/ss-deployment-windows-non-docker/spec.md`
- Affected code: `src/infra/`, `src/main.py`, `src/api/`
- Breaking change: NO
- User benefit: Windows VPS can run SS directly with a single startup command and a working UI at `/`.
