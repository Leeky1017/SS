# Notes: issue-222-ss-frontend-desktop-pro

## Source of truth to replicate
- UI markup + copy: `index.html`
- CSS variables/primitives:
  - `assets/desktop_pro_theme.css`
  - `assets/desktop_pro_layout.css`
  - `assets/desktop_pro_components.css`
  - `assets/desktop_pro_step3.css`

## API surfaces used by the v1 loop
- `POST /v1/jobs`
- `POST /v1/jobs/{job_id}/inputs/upload`
- `GET /v1/jobs/{job_id}/inputs/preview`
- `GET /v1/jobs/{job_id}/draft/preview`
- `POST /v1/jobs/{job_id}/confirm`
- `GET /v1/jobs/{job_id}`
- `GET /v1/jobs/{job_id}/artifacts`
- `GET /v1/jobs/{job_id}/artifacts/{artifact_id:path}`

## Step 3 downgrade strategy (backend is partial)
- Missing `draft/patch` → hide/disable “应用澄清并刷新预览”; show a non-blocking inline hint.
- Missing `stage1_questions`/`open_unknowns`/`data_quality_warnings`/`decision` → hide the corresponding panels and do not gate confirmation on missing data.
- Missing candidate columns → dropdown candidates fall back to inputs preview `columns[].name`; if still empty, render variables read-only and hide dropdowns.

## Later (out of scope for this issue)
- Implement actual `frontend/` code (split into FE-C001–FE-C006 issues).

