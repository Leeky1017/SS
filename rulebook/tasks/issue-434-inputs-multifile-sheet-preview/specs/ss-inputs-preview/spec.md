# Spec delta: ss-inputs-preview (ISSUE-434)

## Scope
- Multi-file upload UX: 1 primary dataset (required) + 0..N auxiliary datasets (optional).
- Excel sheet selection for preview/execution and persisted selection in `inputs/manifest.json`.
- Inputs preview returns a bounded sample plus basic dataset stats and avoids `Unnamed:*` column names.

## Requirements

### R1: Inputs upload distinguishes roles
- Client MUST upload exactly one `primary_dataset`.
- Client MAY upload zero or more `auxiliary_data` datasets.
- `inputs/manifest.json` MUST record each dataset `role`.

### R2: Excel sheet selection is user-driven and persisted
- Preview response MUST include `sheet_names[]` for Excel primary datasets when available.
- API MUST accept a sheet selection update and persist it into the primary dataset entry in `inputs/manifest.json` (`sheet_name`).
- Preview MUST reflect the selected `sheet_name`.

### R3: Preview UX metadata
- Preview response MUST include total `row_count` and `column_count` (best-effort).
- Preview MUST normalize column names to avoid `Unnamed:*` (replace with stable placeholders like `col_1`).
