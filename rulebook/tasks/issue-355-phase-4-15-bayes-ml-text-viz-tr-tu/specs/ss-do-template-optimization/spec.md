# Spec delta: issue-355-phase-4-15-bayes-ml-text-viz-tr-tu

## Goal

Audit TR*–TU* Bayes/ML/Text/Viz templates under the Stata 18 smoke-suite harness:

- 0 `fail` runs for all templates in scope using fixtures.
- Anchors are pipe-delimited: `SS_EVENT|k=v` (no legacy `SS_*:` variants).
- Failures and warnings emit explicit `SS_RC|code=<rc>|where=<context>|message=<...>` anchors.
- Template style is normalized (headers/steps/naming/seeds) without changing the overall system architecture.

## Scope

- Templates: TR01–TR10, TS01–TS12, TT01–TT10, TU01–TU14.
- Evidence: smoke-suite JSON report written by `python -m src.cli run-smoke-suite --manifest ...`.

## Non-goals

- Statistical best-practice upgrades beyond removing run-time fragility.
- Introducing new SSC dependencies.

