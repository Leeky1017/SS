# Proposal: issue-445-frontend-static-mount

## Why
Building `frontend/dist` makes `create_app()` mount `StaticFiles` at `/`, which currently returns `405` for POST requests to unknown paths (e.g. `/jobs`, `/v1/jobs`). This breaks routing-surface expectations and makes `pytest -q` fail locally after building the UI.

Also, `load_config()` best-effort loads `.env`, so local `.env` values can unintentionally change production-startup tests.

## What Changes
- Wrap the frontend `StaticFiles` mount so non-GET/HEAD methods return `404` instead of `405`.
- Add regression tests ensuring unknown POST routes stay `404` even when `frontend/dist` exists.
- Make the production-startup upload-store test deterministic by explicitly setting expected upload env vars.

## Impact
- Affected specs:
  - `openspec/specs/ss-frontend-backend-alignment/spec.md` (clarify non-routable `/v1/jobs` behavior)
- Affected code:
  - `src/main.py`
  - `tests/test_frontend_static_mount.py`
  - `tests/test_production_startup_upload_store.py`
- Breaking change: YES/NO
- Breaking change: NO
- User benefit: building the frontend no longer changes API 404/405 semantics; tests remain deterministic across developer machines.
