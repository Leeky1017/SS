# Proposal: issue-151-composition-adaptive-multi-data

## Why
Phase-3 composition is currently MVP-grade: it assumes a single “primary dataset” can be chained between templates.
Real empirical workflows usually involve 2+ data files (primary data + controls + panel/aux). SS needs an adaptive
composition mechanism that can pick an appropriate strategy (sequential vs merge vs parallel) without forcing all
jobs into an over-engineered workflow engine.

## What Changes
- Upgrade the Phase-3 task card goal/scope from “single dataset chaining” to “adaptive multi-dataset composition”.
- Add a composition architecture design doc describing:
  - dataset roles and data-flow model,
  - supported execution modes and when to use them,
  - an LLM Plan schema extension for explicit data-flow declarations and intermediate products.
- Split Phase-3 into implementable sub task cards (P3.1/P3.2/P3.3) if the scope is too large for one card.

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/README.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-3__template-composition-pipeline-mvp.md`
  - `openspec/specs/ss-do-template-optimization/COMPOSITION_ARCHITECTURE.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-3.1__multi-dataset-inputs-and-roles.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-3.2__composition-plan-schema-and-routing.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-3.3__composition-executor-modes-and-evidence.md`
- Affected code: none in this change (spec/task planning only)
- Breaking change: NO
- User benefit: realistic multi-file analysis composition with explicit, auditable wiring and minimal complexity for simple cases.
