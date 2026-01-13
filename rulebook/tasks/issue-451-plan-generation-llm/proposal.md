# Proposal: issue-451-plan-generation-llm

## Why
Current plan generation is a fixed rule-based flow, which cannot express multi-stage analysis,
conditional branching, or multi-template orchestration for complex empirical requirements.

## What Changes
- Add an LLM-backed plan generation path (prompt + parser) that maps requirement → multi-step plan.
- Extend plan schema with `plan_source`, richer step metadata, and additional semantic step types.
- Keep rule-based plan generation as a safe fallback when LLM output is invalid/unsupported.

## Impact
- Affected specs: `openspec/specs/ss-llm-brain/spec.md`
- Affected code: `src/domain/plan_service.py`, `src/domain/models.py`, new `src/domain/plan_generation_*.py`
- Breaking change: NO (backward compatible defaults)
- User benefit: Better plan quality and flexibility for complex requirements, with safe fallback.
