# Spec: ss-deployment-docker-readiness (issue-387)

## Purpose

Provide a minimal, reproducible production Docker build entrypoint for SS (API + worker).

## Requirements

### Requirement: Repository root Dockerfile builds a production image

SS MUST provide a repository-root `Dockerfile` based on `python:3.12-slim` (or equivalent).

The image MUST allow starting the API and worker as separate containers from the same image by using different commands:
- API: `python -m src.main`
- Worker: `python -m src.worker`

The image MUST NOT install Stata; Stata provisioning is an operator concern (host-mounted strategy).

#### Scenario: Image builds without interaction
- **GIVEN** the repository root contains a production `Dockerfile`
- **WHEN** operators run `docker build -t ss:prod .`
- **THEN** the build succeeds without modifying repository contents
