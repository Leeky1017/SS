# Proposal: issue-147-llm-two-stage-template-selection

## Summary

ADDED:
- Two-stage LLM selection protocol:
  - Stage 1: select canonical family IDs from `FamilySummary[]`
  - Stage 2: select `template_id` from a token-budgeted candidate set (`TemplateSummary[]`)
- Hard verification + bounded retry when `template_id` is not a candidate.
- Run evidence artifacts capturing: candidate families/templates, reasons, and final choice.

## Impact

- Enables scalable selection across 300+ templates without prompting the full library.
- Makes selection auditable and verifiable via persisted evidence artifacts and schema validation.

