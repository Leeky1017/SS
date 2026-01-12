# Spec: ss-deployment-docker-readiness

## Purpose

Define the minimum requirements and acceptance criteria for deploying SS to a remote production server via Docker, including: API + Worker services, MinIO integration, Stata provisioning strategy, supported input formats, and supported output artifacts (including a unified post-run output formatter).

## Related specs (normative)

- Constitutional constraints: `openspec/specs/ss-constitution/spec.md`
- Ports/services split (API vs worker): `openspec/specs/ss-ports-and-services/spec.md`
- Worker/queue contract: `openspec/specs/ss-worker-queue/spec.md`
- Stata runner contract: `openspec/specs/ss-stata-runner/spec.md`
- Do-template library contract: `openspec/specs/ss-do-template-library/spec.md`
- Job workspace + artifacts indexing: `openspec/specs/ss-job-contract/spec.md`
- Upload sessions + S3-compatible deployment baseline: `openspec/specs/ss-deployment-docker-minio/spec.md`
- Delivery workflow gates: `openspec/specs/ss-delivery-workflow/spec.md`

## Requirements

### Requirement: SS provides a production Dockerfile for API + worker

SS MUST provide a repository-root `Dockerfile` that can build a production image containing:
- SS API entrypoint (runs the HTTP server)
- SS worker entrypoint (runs the job execution loop)

The image MUST allow API and worker to be started as separate containers from the same image (different entrypoints/commands).

#### Scenario: Dockerfile exists and is buildable
- **WHEN** operators run `docker build -t ss:prod .`
- **THEN** the build succeeds without modifying the repository contents

### Requirement: docker-compose defines MinIO + SS API + SS worker

SS MUST provide a `docker-compose.yml` suitable as a production deployment starting point, containing service definitions for:
- `minio` (S3-compatible object store)
- `ss-api` (SS HTTP API)
- `ss-worker` (SS worker process)

The compose file MUST define durable volumes for job storage and queue storage.

#### Scenario: Compose includes the full service topology
- **WHEN** operators review `docker-compose.yml`
- **THEN** it includes `minio`, `ss-api`, and `ss-worker` services with explicit volumes for jobs/queue

### Requirement: Stata provisioning strategy is explicit and configurable

The SS worker requires Stata to execute templates. Deployments MUST support at least one of the following strategies:
- Image-bundled Stata: Stata is installed inside the image and `SS_STATA_CMD` points to the in-image executable.
- Host-mounted Stata: Stata is installed on the host and mounted into the worker container; `SS_STATA_CMD` points to the mounted executable path.

Deployments MUST treat the Stata strategy as explicit configuration and MUST NOT rely on silent runtime fallbacks.

#### Production recommendation: host-mounted Stata (default strategy)

For SS production deployments, SS SHOULD prefer the **host-mounted** strategy by default because Stata is proprietary and operators typically need to manage license/installers outside of SS images and repos.

Host-mounted provisioning contract (normative defaults):
- Host pre-installs **Linux** Stata (example install dir: `/opt/stata18`).
- `ss-worker` bind-mounts the host install directory into the container at a stable path: `/mnt/stata:ro`.
- `SS_STATA_CMD` MUST be set to the mounted executable path (example: `/mnt/stata/stata-mp`).
- The mount MUST be read-only and SS MUST NOT ship Stata installers/licenses in git or container images.

Operator verification tips:
- Confirm the host path exists: `ls -la /opt/stata18` (example).
- Confirm the container sees the executable: `ls -la /mnt/stata/stata-mp`.
- If Stata fails to start due to missing shared libs, use `ldd /mnt/stata/stata-mp | rg "not found"` inside the container and install the missing OS packages in the SS image.

#### Windows Server + Docker Desktop (WSL2 backend) deployment notes

Some deployments may need to use a host-installed **Windows** Stata binary via WSL (for example when operators only have a Windows install/license).

Example `SS_STATA_CMD` for Windows Stata 18 MP:
- `/mnt/c/Program Files/Stata18/StataMP-64.exe`

Operational notes:
- When injecting a path with spaces via a `.env` file, operators SHOULD quote it (example: `SS_STATA_CMD="/mnt/c/Program Files/Stata18/StataMP-64.exe"`).
- When running `ss-worker` inside Docker, the configured Windows path MUST be visible inside the container (for example by bind-mounting the host directory at the same container path; `docker-compose.yml` supports this via `SS_STATA_HOST_DIR` + `SS_STATA_CONTAINER_DIR`).
- Operators MUST ensure the configured `SS_STATA_CMD` is executable from the worker runtime environment.
- Docker Desktop Linux containers do not provide WSL Windows interop by default; if interop is unavailable inside containers, operators SHOULD use a Linux Stata binary mounted into the container (the default `/mnt/stata:ro` strategy) or run the worker directly in WSL2 (non-containerized).

#### Scenario: Worker startup is gated on SS_STATA_CMD
- **WHEN** `ss-worker` starts without `SS_STATA_CMD` configured
- **THEN** startup fails fast with a structured error (stable `error_code=STATA_CMD_NOT_CONFIGURED`) and does not attempt to run jobs

#### Scenario: Worker startup fails when the mounted Stata binary is missing
- **WHEN** `SS_STATA_CMD` is configured but the referenced executable is not present/executable in the container (for example the host mount is missing)
- **THEN** startup fails fast with a structured error (stable `error_code=STATA_CMD_INVALID`) and does not attempt to run jobs

### Requirement: Python dependencies are explicitly pinned for production builds

SS MUST provide at least one explicit, reproducible dependency lock for production Docker builds:
- a pinned `requirements.txt`, or
- a dependency lock file used by the chosen installer (for example `uv.lock` or `poetry.lock`)

#### Recommendation: `requirements.txt` generated from `pyproject.toml`

SS SHOULD prefer a pinned, repo-root `requirements.txt` generated from `pyproject.toml` because it is installer-agnostic and works with plain `pip` in production images.

Source of truth + update strategy:
- `pyproject.toml` is the source of truth; `requirements.txt` is derived and MUST NOT be edited manually.
- Regenerate the lock when changing dependency intent in `pyproject.toml`.
- Refresh pinned versions within the same intent periodically (or for security updates) by regenerating with upgrades enabled.

Generation commands (example, Python 3.12):
- Create an isolated venv and install the generator: `python3 -m venv .venv && . .venv/bin/activate && python -m pip install -U pip pip-tools`
- Generate the lock: `pip-compile --strip-extras pyproject.toml -o requirements.txt`
- Upgrade pinned versions (within constraints): `pip-compile --strip-extras --upgrade pyproject.toml -o requirements.txt`

Docker build assets (such as a repo-root `Dockerfile`) SHOULD install dependencies from `requirements.txt` (for example: `python -m pip install -r requirements.txt`).

#### Scenario: A pinned dependency source exists
- **WHEN** reviewing the repository root
- **THEN** at least one pinned dependency source exists for production builds (`requirements.txt` or a lock file)

### Requirement: Supported upload formats are explicit and validated

SS MUST explicitly support uploading and ingesting these primary dataset formats:
- CSV
- XLSX
- XLS
- DTA

If a client uploads an unsupported format, SS MUST reject it with a structured error that states the supported formats.

#### Scenario: Supported input formats are enforced
- **WHEN** a client uploads an unsupported dataset format
- **THEN** SS rejects the request with a structured error describing supported formats (CSV/XLSX/XLS/DTA)

### Requirement: Do-template data shape capability is auditable (wide/long/panel)

SS MUST maintain an auditable statement of do-template library capability for:
- wide tables (many columns)
- long tables (row-wise observations)
- panel data (entity/time identifiers; panel transforms/regressions)

The capability statement MUST be grounded in the actual library under `assets/stata_do_library/` (template inventory + template metadata + code behavior).

#### Scenario: Do-template data capability can be reviewed
- **WHEN** reviewing the do-template library under `assets/stata_do_library/`
- **THEN** the repository provides evidence of wide/long/panel capability coverage (inventory + examples)

### Requirement: Supported output artifacts are explicit and indexed

SS MUST treat outputs as first-class artifacts and MUST index them in the job artifacts index (`job.json`).

At minimum, every successful run MUST preserve these raw artifacts:
- CSV (tables/datasets produced by templates)
- LOG (Stata execution log)
- DO (the executed do-file)

#### Scenario: Baseline raw artifacts are always preserved
- **WHEN** a job run succeeds
- **THEN** the artifacts index includes at least CSV + LOG + DO entries

### Requirement: Unified Output Formatter converts raw artifacts to requested formats

SS MUST support users specifying requested output formats when submitting a job to run:
- Parameter name: `output_formats`
- Type: `string[]`
- Default when omitted: `["csv", "log", "do"]`

After template execution completes, SS MUST run a single unified “Output Formatter” post-processing step that:
- reads the run’s raw artifacts (CSV/LOG/DO and any other intermediate outputs),
- converts/produces the requested formats, and
- registers the produced artifacts in the artifacts index.

Supported output formats MUST include at least:
- `csv` (raw)
- `xlsx` (Excel)
- `dta` (Stata data)
- `docx` (Word report)
- `pdf` (PDF report)
- `log` (Stata log)
- `do` (Stata code)

For report generation, SS SHOULD prefer Stata-native `putdocx` / `putpdf` as the primary implementation strategy.

#### Scenario: Default output formats are applied when omitted
- **WHEN** a job is submitted without `output_formats`
- **THEN** SS produces and indexes the default outputs `csv`, `log`, and `do`

#### Scenario: Output Formatter produces requested formats
- **WHEN** a job is submitted with `output_formats=["docx","pdf","xlsx","csv"]`
- **THEN** SS produces and indexes artifacts for `docx`, `pdf`, `xlsx`, and `csv`

### Requirement: Docker deployment gate is end-to-end verifiable

SS MUST provide a Docker end-to-end deployment verification that starts from `docker-compose up` and reaches a clear READY state with:
- API responding
- worker processing jobs
- MinIO usable for uploads (when enabled)
- requested outputs produced and downloadable as artifacts

#### Scenario: Docker compose run completes the full journey
- **WHEN** operators run `docker-compose up` and execute a minimal job journey end-to-end
- **THEN** the system reaches READY with expected artifacts available for download

## Task cards

Task cards for this spec live under: `openspec/specs/ss-deployment-docker-readiness/task_cards/`.
