# Proposal: issue-178-p52-core-t21-t50

## Summary

Enhance do templates `T21`–`T50` to be more production-grade: explicit best-practice decisions, reduce SSC dependencies (prefer Stata 18 native outputs), strengthen input validation and warn/fail behavior, and add bilingual comments for key assumptions and steps.

## Scope

MODIFIED:
- `assets/stata_do_library/do/T21_*.do` … `T50_*.do`: best-practice upgrades + decision record + bilingual comments; remove optional `estout/esttab` usage; strengthen error handling; upgrade outputs.
- `assets/stata_do_library/do/meta/T21_*.meta.json` … `T50_*.meta.json`: align declared deps/outputs with updated do templates.

NOT IN SCOPE:
- Taxonomy/index redesign or adding new external dependencies.

