# Proposal: issue-434-inputs-multifile-sheet-preview

## Why
- Current Step 2 only supports single-file upload and a basic preview; users need to upload one primary dataset plus optional auxiliary datasets, select Excel sheets, and reliably preview usable columns.

## What Changes
- Frontend Step 2: split upload UI into "主文件（必选）" + "辅助文件（可选）" and add Excel sheet dropdown + improved preview table layout and stats.
- Backend inputs preview: return richer preview metadata (total rows/cols, inferred types already provided) and support Excel sheet selection persisted into `inputs/manifest.json`.

## Impact
- Affected specs: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Affected code: `frontend/src/features/step2/*`, `src/domain/dataset_preview.py`, `src/domain/do_file_generator.py`, `src/api/inputs_*`, `src/domain/inputs_*`
- Breaking change: NO (additive fields/endpoints)
- User benefit: Multi-file upload, correct Excel sheet selection, and a more usable preview for column sanity checks.
