# Proposal: Template Selection Enhancement (V2 / Multi-template)

## Issue
- GitHub: #449
- Priority: P1

## Summary

Enhance `do_template_selection` to support multi-template combination scenarios (e.g., “descriptive stats → regression”) by introducing V2 selection schemas and updating prompting + service logic to return a primary template and optional supplementary templates with a recommended sequence.

## Scope

- Add V2 schema models:
  - `Stage1FamilySelectionV2`
  - `Stage2TemplateSelectionV2`
- Update prompting:
  - Stage-1: detect combination needs + recommend analysis sequence
  - Stage-2: select primary + supplementary templates
- Update service:
  - Parse/handle v2 outputs (still accept v1)
  - Confidence thresholds (<0.6 needs confirmation, <0.3 manual fallback)
  - Persist richer evidence artifacts
- Tests:
  - Multi-stage / multi-template scenarios
  - Confidence threshold behavior

## Non-goals

- No pipeline execution / plan composition changes (still persists primary selection to `job.selected_template_id`).

## Validation

- `ruff check .`
- `pytest -q`

