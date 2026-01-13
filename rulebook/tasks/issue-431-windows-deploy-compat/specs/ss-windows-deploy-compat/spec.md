# Spec: ss-windows-deploy-compat (issue-431)

## Purpose

Make SS runnable on Windows hosts without Docker by removing Unix-only dependencies, ensuring configuration loads, and exposing the built UI from the API server.

Canonical spec: `openspec/specs/ss-deployment-windows-non-docker/spec.md`

## Requirements

### Requirement: Infra file locking is cross-platform

Infra adapters that persist to local files MUST acquire an exclusive file lock in a cross-platform way:
- Windows: `msvcrt`
- Unix: `fcntl`

#### Scenario: Windows startup does not import fcntl
- **GIVEN** SS is installed on a Windows host
- **WHEN** running `python -m src.main` on Windows
- **THEN** it starts without `ModuleNotFoundError: No module named 'fcntl'`

### Requirement: .env is loaded on process start

SS MUST load a `.env` file on process start (best-effort) so `src/config.py` sees required environment variables on Windows shells.

#### Scenario: .env values are visible to config
- **GIVEN** `.env` contains `SS_LLM_PROVIDER=openai-compatible`
- **WHEN** running `python -m src.main`
- **THEN** configuration validation sees `SS_LLM_PROVIDER` as set

### Requirement: Frontend is served at /

The API server MUST serve the built frontend from `frontend/dist` at `/`, while keeping API routes reachable.

#### Scenario: Root path serves the UI
- **GIVEN** `frontend/dist` exists on disk
- **WHEN** an operator visits `GET /`
- **THEN** the response serves the frontend `index.html`

### Requirement: Operators can start SS with one script

SS MUST include a Windows script to load `.env` and start the API and worker.

#### Scenario: start.ps1 starts both processes
- **GIVEN** an operator has created a virtualenv and configured `.env`
- **WHEN** running `powershell -ExecutionPolicy Bypass -File start.ps1`
- **THEN** the API starts and the worker starts in a separate process
