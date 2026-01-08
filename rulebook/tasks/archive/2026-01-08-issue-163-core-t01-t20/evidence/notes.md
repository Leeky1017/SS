# Notes: issue-163-core-t01-t20

## Scope locks
- Only templates `T01`–`T20`.
- No methodology redesigns (Phase 5); focus is on Stata 18 runnability + contract compliance.

## Anchor normalization
- Remove legacy variants like `SS_TASK_VERSION:...`, `SS_ERROR:...`, `SS_ERR:...`.
- Keep pipe-delimited `SS_EVENT|k=v` anchors (per `assets/stata_do_library/SS_DO_CONTRACT.md`).

## Later (out of scope)
- Expanding the default smoke-suite manifest beyond the minimal baseline set.

