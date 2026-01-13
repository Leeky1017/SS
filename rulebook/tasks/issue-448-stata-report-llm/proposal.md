# Proposal: Stata Result Interpretation Report

## Issue
- GitHub: #448
- Priority: P0

## Summary

Implement end-to-end Stata result interpretation report generation:

- Rule-based parser extracts all numerical values (coef/SE/p-value/R²/N) from exported Stata artifacts.
- LLM only turns extracted numbers into natural language; prompt explicitly forbids number modification/fabrication.
- Service orchestrates extraction → prompt → LLM → parse → writes a Markdown report artifact.

## Scope

- New domain modules:
  - `src/domain/stata_report_models.py`
  - `src/domain/stata_result_parser.py`
  - `src/domain/stata_report_llm.py`
  - `src/domain/stata_report_service.py`
- Update artifact enum:
  - `src/domain/models.py` (`ArtifactKind.STATA_REPORT_INTERPRETATION`)
- Tests:
  - `tests/test_stata_report_models.py`
  - `tests/test_stata_result_parser.py`
  - `tests/test_stata_report_llm.py`
  - `tests/test_stata_report_service.py`
- Delivery log:
  - `openspec/_ops/task_runs/ISSUE-448.md`

## Non-goals

- No UI/API wiring changes.
- No speculative analysis types beyond OLS / Panel FE / DID / descriptive stats.

## Validation

- `ruff check .`
- `pytest -q`

