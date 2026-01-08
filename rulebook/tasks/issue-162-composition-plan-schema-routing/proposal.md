# Proposal: issue-162-composition-plan-schema-routing

## Why
- SS needs a schema-bound, composition-aware plan so the LLM can choose the simplest valid workflow (sequential for simple jobs; richer modes only when needed).

## What Changes
- Define composition plan schema conventions (reserved `params` keys) and validation rules for `composition_mode`, `dataset_ref`, `input_bindings`, and `products`.
- Add planner routing logic that selects the minimal supported `composition_mode` for the job and records it in the plan.
- Add fixtures + tests covering complex plan shapes and validation failures.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/COMPOSITION_ARCHITECTURE.md`
- Affected code: `src/domain/plan_service.py` + composition plan schema/validation module(s)
- Breaking change: NO (plan remains `LLMPlan` v1; new fields are additive)
- User benefit: keeps simple jobs simple while enabling explicit, verifiable multi-dataset composition planning.
