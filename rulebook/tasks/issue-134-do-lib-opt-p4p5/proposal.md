# Proposal: issue-134-do-lib-opt-p4p5

## Why
Phase 0–3 of `ss-do-template-optimization` focus on meta/index/taxonomy/composition, but do not cover systematic review of **template code quality** (Stata 18 runtime) nor **methodological/content upgrades**. We need explicit Phase 4/5 plans to make the library production-grade and auditable.

## What Changes
- Add Phase 4/5 task cards for full-library Stata 18 audit and best-practice content enhancement.
- Update the spec README rollout phases to include Phase 4/5.
- Add a template quality assessment report to capture static findings + define runtime evidence requirements.
- Add an OpenSpec run log for Issue #134.

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/README.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-4__code-quality-audit.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5__content-enhancement.md`
  - `openspec/specs/ss-do-template-optimization/TEMPLATE_QUALITY_ASSESSMENT.md`
- Affected code: none (spec/planning only)
- Breaking change: NO
- User benefit: Clear, auditable roadmap for getting the Stata template library to “Stata 18 runs + best-practice methods” quality.
