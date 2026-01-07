# Phase 1: Canonical Taxonomy (Families, Keywords, Aliases)

## Metadata

- Issue: #146
- Parent: #125
- Related specs:
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Introduce an SS-owned canonical taxonomy that eliminates ambiguous family duplication and provides retrieval-oriented metadata (keywords/use_when/fallbacks).

## In scope

- Define canonical `family` registry:
  - canonical IDs
  - aliases (human synonyms; legacy family ids if needed)
  - keywords + use_when
  - fallback map for low-confidence selection
- Map existing library families/modules to the canonical set (no duplicated canonical families).
- Produce a generated `FamilySummary` view for LLM Stage-1 selection.

## Out of scope

- Two-stage selection implementation (separate card).
- Template body refactors (separate card).

## Acceptance checklist

- [x] A canonical family registry exists (versioned, test-covered)
- [x] All templates resolve to exactly 1 canonical family
- [x] Aliases resolve deterministically and are audited in artifacts/run meta
- [x] Stage-1 `FamilySummary` generation exists and is stable under regeneration

## Completion

- PR: https://github.com/Leeky1017/SS/pull/148
- Added versioned canonical family registry + JSON Schema.
- Canonicalized all 319 templates into 28 canonical families (dedup: panel/descriptive/survival/audit via aliases).
- Generated stable token-budgeted `FamilySummary` and locked it with CI tests.
- Run log: `openspec/_ops/task_runs/ISSUE-146.md`
