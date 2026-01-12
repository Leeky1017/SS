# ISSUE-387
- Issue: #387
- Branch: task/387-deploy-ready-r010 (merged) / task/387-deploy-ready-r010-closeout
- PR: https://github.com/Leeky1017/SS/pull/393

## Plan
- Add repo-root `Dockerfile` + `.dockerignore` for production image builds.
- Validate `docker build` and both runtime commands (API/worker) from the same image.
- Open PR, enable auto-merge, and record evidence.

## Runs
### 2026-01-12 15:19 docker-cli-check
- Command: `docker version`
- Key output: `The command 'docker' could not be found in this WSL 2 distro.`
- Evidence: Docker is not available in this dev environment; validate via CI or a machine with Docker installed.

### 2026-01-12 15:19 ruff
- Command: `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: N/A

### 2026-01-12 15:19 pytest
- Command: `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output: `184 passed, 5 skipped in 11.24s`
- Evidence: N/A

### 2026-01-12 15:20 pip-install
- Command: `/home/leeky/work/SS/.venv/bin/python -m pip install .`
- Key output: `Successfully built ss` / `Successfully installed ss-0.0.0`
- Evidence: Confirms Dockerfile `pip install .` step is buildable in a clean PEP517 flow.

### 2026-01-12 15:21 api-start-smoke
- Command: `SS_LLM_PROVIDER=yunwu SS_LLM_API_KEY=dummy SS_LLM_MODEL=dummy timeout 3s /home/leeky/work/SS/.venv/bin/python -m src.main`
- Key output: `SS_API_STARTUP` / `Uvicorn running on http://0.0.0.0:8000` / `SS_API_SHUTDOWN_COMPLETE`
- Evidence: Exited with `124` due to `timeout` (expected for smoke run).

### 2026-01-12 15:21 worker-start-smoke
- Command: `SS_LLM_PROVIDER=yunwu SS_LLM_API_KEY=dummy SS_LLM_MODEL=dummy SS_STATA_CMD=stata-mp timeout 3s /home/leeky/work/SS/.venv/bin/python -m src.worker`
- Key output: `SS_WORKER_STARTUP` / `SS_WORKER_RUNNER_SELECTED` / `SS_WORKER_SHUTDOWN_COMPLETE`
- Evidence: Exited with `124` due to `timeout` (expected for smoke run).

### 2026-01-12 15:43 requirements-install-smoke
- Command: `python3 -m venv /tmp/ss-r010-requirements && pip install -r requirements.txt`
- Key output: `Successfully installed ...` (pinned wheels resolved on Python 3.12)
- Evidence: Confirms Dockerfile dependency install path (`pip install -r requirements.txt`) is viable.

## Docker Validation (run on a machine with Docker)

- Build: `docker build -t ss:prod .`
- API: `docker run --rm -p 8000:8000 -e SS_LLM_PROVIDER=yunwu -e SS_LLM_API_KEY=dummy -e SS_LLM_MODEL=dummy ss:prod`
- Worker: `docker run --rm -e SS_LLM_PROVIDER=yunwu -e SS_LLM_API_KEY=dummy -e SS_LLM_MODEL=dummy -e SS_STATA_CMD=stata-mp ss:prod python -m src.worker`
