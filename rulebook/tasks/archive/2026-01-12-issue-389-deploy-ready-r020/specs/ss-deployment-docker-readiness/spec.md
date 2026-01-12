# Spec Delta: ss-deployment-docker-readiness (issue-389-deploy-ready-r020)

## Context

This task implements the `ss-deployment-docker-readiness` requirement: "Python dependencies are explicitly pinned for production builds".

## Requirements

- Source of truth MUST remain `pyproject.toml` (`[project].dependencies`).
- The repo root MUST include a pinned `requirements.txt` suitable for production Docker builds.
- `requirements.txt` MUST be generated from `pyproject.toml` using `pip-compile` (recommended: `pip-compile --strip-extras ...`).
- Update strategy MUST be explicit:
  - Change dependency intent in `pyproject.toml`, then regenerate `requirements.txt`.
  - For upgrades within the same intent, run `pip-compile --strip-extras --upgrade ...` and commit the updated lock.

## Scenarios

- **WHEN** reviewing the repository root
- **THEN** `requirements.txt` exists and pins versions with `==`.

- **WHEN** building a production image
- **THEN** Docker build assets install dependencies from `requirements.txt` (or provide an explicit alternative with equivalent lock semantics).
