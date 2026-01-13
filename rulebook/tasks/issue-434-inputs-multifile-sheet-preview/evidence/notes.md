# Notes — ISSUE-434

## Reference
- Legacy reference project: `/home/leeky/work/stata_service/` (frontend has multi-file + main dataset selection patterns).

## Decisions
- Store Excel sheet selection in `inputs/manifest.json` under the primary dataset entry (field: `sheet_name`).
- Preview API returns `sheet_names[]` so UI can render a dropdown when `len(sheet_names) > 1`.

## Later
- Consider making plan id incorporate sheet selection (currently plan id uses `job.inputs.fingerprint` only).
