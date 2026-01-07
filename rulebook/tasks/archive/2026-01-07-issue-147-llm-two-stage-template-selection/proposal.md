# Proposal: issue-147-llm-two-stage-template-selection

## Why

Selecting from 300+ templates by injecting the full library into a single prompt is both slow and token-expensive.
We need a two-stage selection protocol (family → template) that stays within a fixed token budget while remaining
verifiable (hard membership checks) and auditable (persisted selection evidence).

## What Changes

- Add a two-stage LLM selection protocol:
  - Stage 1: select canonical family IDs from `FamilySummary[]`
  - Stage 2: select `template_id` from a token-budgeted candidate set (`TemplateSummary[]`)
- Enforce hard verification + bounded structured retry when `family_id` / `template_id` is not in the candidate set.
- Persist run evidence artifacts capturing: candidates, reasons, confidence, and final choice.
- Add deterministic token budgeting + topK trimming with unit tests.

## Impact

- Affected specs:
  - `openspec/specs/ss-do-template-optimization/spec.md`
- Affected code:
  - `src/domain/do_template_selection_service.py`
  - `src/infra/llm_tracing.py`
- Breaking change: NO
- User benefit: scalable, auditable template selection without token blowups.
