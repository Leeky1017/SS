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

### Requirement: Operators can start SS with start.ps1

SS MUST include a PowerShell launcher `start.ps1` so Windows operators can start the API and worker with one command.

`start.ps1` MUST:
- load `.env` best-effort (non-overriding)
- start the API in the foreground and the worker in a separate background process
- stop the worker process when the API exits (best-effort, including Ctrl+C)

#### Scenario: start.ps1 starts both processes
- **GIVEN** an operator has configured `.env`
- **WHEN** running `powershell -ExecutionPolicy Bypass -File start.ps1`
- **THEN** the API starts and the worker starts in a separate process

#### Scenario: Ctrl+C stops the worker
- **GIVEN** `start.ps1` is running
- **WHEN** the operator stops the API with Ctrl+C
- **THEN** the worker process is terminated

### Requirement: Frontend is served by the API at /

When `frontend/dist` exists, the API server MUST serve it at `/` so operators can visit `http://<host>:8000/` without separately starting a frontend server.

#### Scenario: Root path serves the UI
- **WHEN** an operator requests `GET /`
- **THEN** the response serves the frontend `index.html`

### Requirement: Docker deployment artifacts are archived

SS MUST NOT advertise Docker as a supported deployment path.

Docker-only deployment assets MUST be archived under `legacy/docker/` and Docker-only OpenSpecs MUST be archived under `openspec/specs/archive/`.

#### Scenario: Repo-root does not expose Docker deployment entrypoints
- **WHEN** an operator inspects the repository root
- **THEN** `Dockerfile`, `docker-compose.yml`, and `.dockerignore` are not present at repo root
