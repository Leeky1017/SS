# ISSUE-297
- Issue: #297 https://github.com/Leeky1017/SS/issues/297
- Branch: task/297-prod-e2e-r001
- PR: <fill-after-created>

## Goal
- In runtime, keep only one authoritative business HTTP surface: `/v1/**` (jobs/draft/bundle/upload-session), removing all non-`/v1` business endpoints (legacy `/jobs/**`), while retaining ops endpoints (`/health/*`, `/metrics`) without business capability.

## Status
- CURRENT: Unversioned business surface removed; adding regression tests + validation runs.

## Next Actions
- [ ] Inventory current router mounts and endpoint list (v1 vs non-v1).
- [ ] Remove unversioned business router mounting; keep ops endpoints only.
- [ ] Add regression test ensuring `/jobs/**` is 404 while `/v1/**` remains.
- [ ] Run `ruff check .` and `pytest -q`.
- [ ] Open PR, enable auto-merge, and verify it is `MERGED`.

## Decisions Made
- 2026-01-10: Implement minimal routing change: remove unversioned `api_router` business surface, introduce a dedicated ops router for `/health/*` and `/metrics`.

## Errors Encountered

## Runs
### 2026-01-10 Setup: Issue + worktree
- Command:
  - `gh issue create -t "[ROUND-01-PROD-A] PROD-E2E-R001: 移除非 /v1 业务路由" -b "<body omitted>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "297" "prod-e2e-r001"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/297`
  - `Worktree created: .worktrees/issue-297-prod-e2e-r001`
  - `Branch: task/297-prod-e2e-r001`
- Evidence:
  - (this file)

### 2026-01-10 Inventory: router mounts (v1 vs non-v1)
- Command:
  - `rg -n "api_v1_router|api_router|include_router\\(" src/api/routes.py src/main.py`
  - `sed -n "1,220p" src/api/routes.py`
  - `sed -n "1,240p" src/main.py`
- Key output:
  - `src/api/routes.py` defines both:
    - unversioned `api_router` includes `jobs`, `draft`, `health`, `metrics`
    - versioned `api_v1_router = APIRouter(prefix="/v1")` includes `jobs`, `draft`, `inputs_bundle`, `inputs_upload_sessions`, `task_codes`
  - `src/main.py` mounts both:
    - `app.include_router(api_v1_router)`
    - `app.include_router(api_router, include_in_schema=False)` → legacy `/jobs/**` is reachable at runtime
- Evidence:
  - `src/api/routes.py`
  - `src/main.py`

### 2026-01-10 Fix: remove unversioned business routers
- Command:
  - Edit: `src/api/routes.py`, `src/main.py`
  - `rg -n "api_router|ops_router" src/api/routes.py src/main.py`
- Key output:
  - Unversioned business routers are no longer mounted:
    - `src/api/routes.py`: `ops_router` contains only `health` + `metrics` (no `jobs`/`draft`)
    - `src/main.py`: mounts `api_v1_router` and `ops_router` (no `api_router`)
- Evidence:
  - `src/api/routes.py`
  - `src/main.py`

### 2026-01-10 Validation: ruff + pytest + curl
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e ".[dev]"`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
  - `uvicorn src.main:app --host 127.0.0.1 --port 8001` + `curl`:
    - `GET /health/live`
    - `GET /metrics`
    - `GET /jobs`
    - `GET /jobs/anything`
- Key output:
  - `ruff`: `All checks passed!`
  - `pytest`: `165 passed, 5 skipped`
  - `curl`:
    - `/health/live=200`
    - `/metrics=200`
    - `/jobs=404`
    - `/jobs/anything=404`
- Evidence:
  - (this file)
