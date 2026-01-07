# Proposal: issue-133-do-lib-opt-p0

## Why
`assets/stata_do_library/` is treated as a data asset by SS, so drift between meta/index/docs and hardcoded environment paths must be blocked by CI.

## What Changes
- Add a versioned JSON Schema for `do/meta/*.meta.json` and validate all meta files in CI.
- Fix and CI-enforce `DO_LIBRARY_INDEX.json` summary consistency (no stale counters).
- Align library docs/contracts that referenced legacy `tasks/` paths with `assets/stata_do_library/`.
- Remove the hardcoded Windows `ado_path` from `CAPABILITY_MANIFEST.json` and CI-enforce it.

## Impact
- Affected specs: `openspec/specs/ss-do-template-library/`, `openspec/specs/ss-do-template-optimization/`
- Affected code: `tests/` only (asset validation)
- Breaking change: NO
- User benefit: SS can rely on the template library as a consistent, schema-validated asset.
