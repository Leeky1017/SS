# Notes — issue-162-composition-plan-schema-routing

## Context
- Task card: `openspec/specs/ss-do-template-optimization/task_cards/phase-3.2__composition-plan-schema-and-routing.md`
- Goal: composition-aware plan schema + validation + planner routing (keep simple single-file jobs simple).

## Decisions
- Use reserved step `params` keys to keep `LLMPlan` v1 stable:
  - `composition_mode` enum
  - `input_bindings` mapping role → `dataset_ref`
  - `products` declared outputs with stable `product_id`

## Later
- Expand routing beyond input-count heuristics once multi-dataset upload + manifest wiring is implemented end-to-end.
