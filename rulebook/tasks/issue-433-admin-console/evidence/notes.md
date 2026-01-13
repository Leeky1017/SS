# Notes: issue-433-admin-console

## Decisions

- Serve admin UI at `/admin` via FastAPI route that returns `frontend/dist/index.html`, and let the React bundle switch into admin mode based on `window.location.pathname`.
- Use file-backed stores for admin tokens and Task Codes under `SS_ADMIN_DATA_DIR` (default: `jobs/_admin`) to keep the initial chain minimal.
- List admin jobs across all tenants by default (with optional tenant filter in API/UI).

## Open Questions

- None.
