# Spec: ss-deployment-windows-non-docker

## Purpose

Define the minimum compatibility requirements for deploying SS directly on Windows hosts (for example a Windows VPS) without Docker.

## Requirements

### Requirement: No Unix-only modules are required at startup

SS MUST start on Windows without importing Unix-only modules (for example `fcntl`).

#### Scenario: Windows can start the API process
- **WHEN** running `python -m src.main` on Windows
- **THEN** the process starts without `ModuleNotFoundError: No module named 'fcntl'`

### Requirement: Local file stores use cross-platform file locking

Components that persist to local files MUST use a cross-platform exclusive file locking strategy:
- Windows MUST use `msvcrt`
- Unix MUST use `fcntl`

#### Scenario: File-backed stores are safe to use on Windows
- **WHEN** the job store or upload session store writes to disk on Windows
- **THEN** it uses a Windows-compatible exclusive lock

### Requirement: .env is loaded for Windows shells

SS MUST load a `.env` file on process start (best-effort) so Windows shells that do not auto-load `.env` still provide required configuration.

#### Scenario: .env values are visible to config
- **GIVEN** `.env` contains `SS_LLM_PROVIDER=openai-compatible`
- **WHEN** running `python -m src.main`
- **THEN** configuration validation sees `SS_LLM_PROVIDER` as set

### Requirement: Frontend is served by the API at /

When `frontend/dist` exists, the API server MUST serve it at `/` so operators can visit `http://<host>:8000/` without separately starting a frontend server.

#### Scenario: Root path serves the UI
- **WHEN** an operator requests `GET /`
- **THEN** the response serves the frontend `index.html`
