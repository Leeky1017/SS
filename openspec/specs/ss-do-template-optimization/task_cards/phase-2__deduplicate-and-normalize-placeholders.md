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

- [ ] Redundant templates are removed from the selectable set (or merged) with docs updated
- [ ] Placeholder normalization is enforced or deterministically normalized in rendering
- [ ] Index regeneration reflects the new inventory (no stale IDs)
- [ ] CI gates catch header/meta/anchor inconsistencies introduced by the merge
