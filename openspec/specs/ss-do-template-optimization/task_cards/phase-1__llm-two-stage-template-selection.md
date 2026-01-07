# Phase 1: LLM Two-Stage Template Selection (Family → Template)

## Metadata

- Issue: TBD
- Parent: #125
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Enable LLM-driven template selection over 300+ templates without injecting the full library into a single prompt, while keeping selection verifiable and auditable.

## In scope

- Stage 1: prompt + schema to select canonical families from `FamilySummary[]`
- Stage 2: build candidate templates from selected families, rank + trim to topK within a token budget, then select a `template_id`
- Hard verification: chosen `template_id` must be in candidate set; otherwise structured retry/fallback (bounded)
- Tests:
  - schema validation
  - candidate-set membership enforcement
  - trimming stays within configured budgets

## Out of scope

- Template composition/pipelines (separate card).
- Deduplicating template inventory (separate card).

## Acceptance checklist

- [ ] Stage-1 family selection produces canonical family IDs (with reasons + confidence)
- [ ] Stage-2 selection enforces `template_id ∈ candidates`
- [ ] Token budgeting + topK trimming is deterministic and test-covered
- [ ] Selection artifacts are written into run evidence (`do_template.*` artifacts)

