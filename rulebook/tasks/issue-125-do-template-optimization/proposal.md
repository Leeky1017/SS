# Proposal: issue-125-do-template-optimization

## Why
SS currently vendors 319 Stata do templates under `assets/stata_do_library/`, but SS code-level integration still only supports a single stub template. Before wiring the full library into the LLM/planner chain, we need a clear optimization strategy to avoid accumulating redundant taxonomy, drifting metadata, and un-auditable selection behavior.

## What Changes
- ADDED: `openspec/specs/ss-do-template-optimization/` (requirements + strategy + task cards)
- ADDED: `openspec/_ops/task_runs/ISSUE-125.md` (delivery run log)
- ADDED: Rulebook spec delta pointer under `rulebook/tasks/issue-125-do-template-optimization/specs/ss-do-template-optimization/spec.md`

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/spec.md`
  - `openspec/specs/ss-do-template-optimization/README.md`
- Affected code: none (doc-only)
- Breaking change: NO
- User benefit: a concrete, staged plan to optimize taxonomy/meta/indexing and enable efficient LLM template selection + composition
