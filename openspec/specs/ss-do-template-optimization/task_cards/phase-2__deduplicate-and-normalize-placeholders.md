# Phase 2: Deduplicate Templates + Normalize Placeholders

## Metadata

- Issue: #155
- Parent: #125
- Related specs:
  - `openspec/specs/ss-do-template-optimization/README.md`

## Goal

Reduce redundancy in the selectable template set and standardize high-frequency placeholder variants to improve maintainability and selection quality.

## In scope

- First-wave dedup (merge/delete) based on exact duplicate signals (`slug`/`title_zh`):
  - Keep `TS01`, delete `TD07` (LASSO)
  - Keep `TS02`, delete `TD08` (Ridge)
  - Keep `TS03`, delete `TD09` (Elastic Net)
  - Keep `TU12`, delete `TD11` (Spline)
  - Keep `TA03`, delete `TU15` (MI)
  - Keep `TQ03`, delete `TH10` (VECM)
  - Keep `TK04`, delete `TH05` (GARCH)
  - Keep `TK20`, delete `TF13` (Fama–MacBeth)
  - Keep `T02`, delete `TB01` (Group descriptives)
- Placeholder normalization:
  - `__DEPVAR__` (remove `__DEP_VAR__`)
  - `__INDEPVARS__` (remove `__INDEP_VARS__`)
  - `__TIME_VAR__` (remove `__TIMEVAR__`)
- Regenerate indices and ensure repo-level validation passes.

## Out of scope

- Deep semantic dedup (near-duplicates) beyond the first wave.
- Composition/pipeline changes.

## Acceptance checklist

- [x] Redundant templates are removed from the selectable set (or merged) with docs updated
- [x] Placeholder normalization is enforced or deterministically normalized in rendering
- [x] Index regeneration reflects the new inventory (no stale IDs)
- [x] CI gates catch header/meta/anchor inconsistencies introduced by the merge

## Completion

- PR: https://github.com/Leeky1017/SS/pull/156
- Run log: `openspec/_ops/task_runs/ISSUE-155.md`
- Summary:
  - Deleted redundant templates (TD07/TD08/TD09/TD11/TU15/TH10/TH05/TF13/TB01) and kept the canonical templates.
  - Standardized placeholders to `__DEPVAR__`, `__INDEPVARS__`, `__TIME_VAR__` across the remaining library.
  - Regenerated `assets/stata_do_library/DO_LIBRARY_INDEX.json` (and taxonomy family summary) from meta and added CI gates for deprecated placeholders.
