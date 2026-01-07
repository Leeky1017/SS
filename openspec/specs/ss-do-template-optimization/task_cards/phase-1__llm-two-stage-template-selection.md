# Phase 1: LLM Two-Stage Template Selection (Family → Template)

## Metadata

- Issue: #147
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

- [x] Stage-1 family selection produces canonical family IDs (with reasons + confidence)
- [x] Stage-2 selection enforces `template_id ∈ candidates`
- [x] Token budgeting + topK trimming is deterministic and test-covered
- [x] Selection artifacts are written into run evidence (`do_template.*` artifacts)

## Completion

- PR: https://github.com/Leeky1017/SS/pull/150
- Implemented two-stage LLM template selection (family → template) with auditable evidence artifacts.
- Enforced hard candidate membership for `family_id` and `template_id` with bounded structured retry.
- Added deterministic token-budgeted candidate trimming and unit tests to prevent regressions.
- Run log: `openspec/_ops/task_runs/ISSUE-147.md`
