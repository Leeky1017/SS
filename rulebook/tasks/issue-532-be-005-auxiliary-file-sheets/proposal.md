# Proposal: issue-532-be-005-auxiliary-file-sheets

## Why
Only the primary Excel dataset supports sheet selection today; auxiliary Excel inputs are always read with default sheet options, which is incorrect for multi-sheet workbooks and blocks UX for panel/data-merge workflows.

## What Changes
- Add `POST /v1/jobs/{job_id}/inputs/datasets/{dataset_key}/sheet` to select an Excel sheet for any dataset.
- Persist `{sheet_name, header_row}` to the inputs manifest for the selected dataset.
- Extend inputs preview response with per-dataset sheet metadata for UI rendering.

## Impact
- Affected specs: `openspec/specs/ss-ux-remediation/task_cards/BE-005__auxiliary-file-sheets.md`
- Affected code: `src/domain/inputs_manifest*`, `src/domain/inputs_sheet_selection_service.py`, `src/domain/job_inputs_service.py`, `src/api/*`
- Breaking change: NO (additive)
- User benefit: auxiliary Excel files can be correctly previewed and used by downstream plan/draft generation
