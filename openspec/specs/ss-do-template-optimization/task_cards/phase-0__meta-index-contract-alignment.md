# Phase 0: Meta/Index/Contract Alignment

## Metadata

- Issue: #133
- Parent: #125
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Make `assets/stata_do_library/` internally consistent and schema-validated so SS can treat the library as a reliable data asset.

## In scope

- Define a versioned JSON Schema for `do/meta/*.meta.json` and validate in CI.
- Regenerate/repair `assets/stata_do_library/DO_LIBRARY_INDEX.json` summaries so it is self-consistent (no stale counters).
- Align library docs/contracts that still reference legacy `tasks/` paths with the SS layout (`assets/stata_do_library/`).
- Remove or make configurable any hardcoded environment paths in library manifests (e.g. Windows `ado_path`).

## Out of scope

- Mass rewrite of template bodies.
- Template selection UX improvements (handled in later phases).

## Acceptance checklist

- [x] A JSON Schema exists and is CI-enforced for all `do/meta/*.meta.json`
- [x] `DO_LIBRARY_INDEX.json` is derived (or validated) so summary fields cannot drift from `tasks.*`
- [x] Library docs/contract paths no longer reference `tasks/` as the SS layout
- [x] `CAPABILITY_MANIFEST.json` has no hardcoded absolute `ado_path` (or it is clearly non-authoritative and ignored by SS)
- [x] `openspec/_ops/task_runs/ISSUE-133.md` includes the validation commands + key outputs for this phase

## Completion

- PR: https://github.com/Leeky1017/SS/pull/137
- Run log: `openspec/_ops/task_runs/ISSUE-133.md`
- Delivered:
  - Versioned meta schema + CI validation
  - Index summary drift fixed + CI-guarded
  - Docs/contracts path aligned; hardcoded `ado_path` removed

