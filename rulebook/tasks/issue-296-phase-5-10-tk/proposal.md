# Proposal: issue-296-phase-5-10-tk

## Why
Phase 4.10 made TK templates runnable and contract-compliant; Phase 5.10 upgrades finance template content with best-practice inference choices, stronger data guardrails, and bilingual guidance.

## What Changes
- Add a standardized best-practice review record block to each TK01–TK20 do-template.
- Strengthen validation for data shape, missingness, and extreme values; emit structured warnings/failures (no silent failure).
- Prefer Stata built-ins; keep SSC deps only when unavoidable (documented in-template).

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/spec.md`
- Affected code: `assets/stata_do_library/do/TK*.do`
- Breaking change: NO
- User benefit: more robust finance analyses with explicit guardrails and reproducible diagnostics
