# Spec: ss-deployment-docker-readiness (issue-403)

## Purpose

Provide a repo-root production `docker-compose.yml` starting point for SS (API + worker) with MinIO, durable state, and explicit Stata/do-template library wiring.

## Requirements

### Requirement: Repo-root docker-compose defines MinIO + SS API + SS worker

SS MUST provide a repository-root `docker-compose.yml` containing service definitions for:
- `minio` (S3-compatible object store)
- `ss-api` (HTTP API)
- `ss-worker` (worker loop)

`ss-api` and `ss-worker` MUST run from the same image and differ only by entrypoint/command.

The compose file MUST define durable volumes for:
- job workspace: `ss-jobs:/var/lib/ss/jobs`
- queue storage: `ss-queue:/var/lib/ss/queue`

#### Scenario: Compose topology is reviewable
- **GIVEN** the repository root contains `docker-compose.yml`
- **WHEN** operators run `docker compose config`
- **THEN** the rendered config includes `minio`, `ss-api`, and `ss-worker` with durable `ss-jobs` and `ss-queue` volumes

### Requirement: Stata and do-template library wiring is explicit in compose

For the host-mounted Stata strategy, the compose recipe MUST:
- bind-mount the host Stata installation directory into the container at `/mnt/stata:ro` (default example: `/opt/stata18:/mnt/stata:ro`)
- set `SS_STATA_CMD=/mnt/stata/stata-mp` for the worker

The compose recipe MUST explicitly set `SS_DO_TEMPLATE_LIBRARY_DIR` to the do-template library path (in-image or via bind mount).

#### Scenario: Worker can start with complete config
- **GIVEN** Stata is mounted at `/mnt/stata:ro` and `SS_STATA_CMD` points to an executable inside the container
- **WHEN** operators run `docker compose up`
- **THEN** `ss-worker` starts successfully and can claim and process queue items
