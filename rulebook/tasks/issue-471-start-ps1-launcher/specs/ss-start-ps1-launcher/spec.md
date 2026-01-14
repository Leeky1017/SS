# Spec: ss-start-ps1-launcher (issue-471)

## Purpose

Make `start.ps1` a reliable one-command launcher for SS on Windows (non-Docker).

Canonical spec: `openspec/specs/ss-deployment-windows-non-docker/spec.md`

## Requirements

### Requirement: start.ps1 starts the API and worker

`start.ps1` MUST start the API in the foreground and start the worker in a separate background process.

#### Scenario: start.ps1 starts both processes
- **GIVEN** an operator has configured `.env`
- **WHEN** running `powershell -ExecutionPolicy Bypass -File start.ps1`
- **THEN** the API starts and the worker starts in a separate process

### Requirement: Worker lifecycle is tied to the API process

When the API process exits (including Ctrl+C), `start.ps1` MUST stop the worker process (best-effort).

#### Scenario: Ctrl+C stops the worker
- **GIVEN** `start.ps1` is running
- **WHEN** the operator stops the API with Ctrl+C
- **THEN** the worker process is terminated

### Requirement: start.ps1 bootstraps a venv when missing

When a venv is not present, `start.ps1` MUST create one so the operator can start SS with a single command.

#### Scenario: start.ps1 creates a venv
- **GIVEN** `.venv` and `venv` do not exist
- **WHEN** running `powershell -ExecutionPolicy Bypass -File start.ps1`
- **THEN** `.venv/Scripts/python.exe` exists after startup
