# Proposal: issue-142-do-lib-opt-p4p5-split

## Why
The existing Phase 4/5 task cards for `ss-do-template-optimization` are monolithic, which blocks parallel execution and makes ownership unclear. We need a finer-grained, theme-based breakdown that can be executed in parallel while keeping scope cohesive (~15–25 templates per card when possible).

## What Changes
- Add 30 task cards (Phase 4: 15, Phase 5: 15) under `openspec/specs/ss-do-template-optimization/task_cards/`.
- Remove the old monolithic cards:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-4__code-quality-audit.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5__content-enhancement.md`
- Update rollout phases in `openspec/specs/ss-do-template-optimization/README.md` to point to the split cards.
- Add an OpenSpec run log for Issue #142.

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/README.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-4.*.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5.*.md`
- Affected code: none (spec/planning only)
- Breaking change: NO
- User benefit: Phase 4/5 work becomes parallelizable and auditable with clearer thematic ownership.

