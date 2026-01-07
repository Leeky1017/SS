# Notes: issue-155-phase-2-deduplicate-and-normalize-placeholders

## Scope locks
- Dedup list is exact and limited to Phase 2 task card (no near-duplicate refactors).
- Placeholder canonical forms:
  - `__DEPVAR__` (no `__DEP_VAR__`)
  - `__INDEPVARS__` (no `__INDEP_VARS__`)
  - `__TIME_VAR__` (no `__TIMEVAR__`)

## Later (out of scope)
- Add alias/redirect mapping for deleted template IDs (if runtime tooling needs it).

