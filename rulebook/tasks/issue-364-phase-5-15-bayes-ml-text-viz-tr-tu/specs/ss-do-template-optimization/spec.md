# Spec delta: issue-364-phase-5-15-bayes-ml-text-viz-tr-tu

## Goal

Content-enhance TR*–TU* Bayes/ML/Text/Viz templates while keeping the Stata-18 smoke-suite baseline:

- Best-practice upgrades (methods + interpretation guidance).
- SSC dependencies removed/replaced where feasible; exceptions are explicitly documented.
- Error handling is strengthened (explicit warn/fail; no silent failure).
- Key steps include bilingual comments (中英文注释).

## Scope

- Templates: TR01–TR10, TS01–TS12, TT01–TT10, TU01–TU14.
- Assets: `assets/stata_do_library/do/*.do`, `assets/stata_do_library/do/meta/*.meta.json`, and supporting dependency documentation.

## Non-goals

- Taxonomy/index/placeholder redesign.
- Introducing new external dependencies.

