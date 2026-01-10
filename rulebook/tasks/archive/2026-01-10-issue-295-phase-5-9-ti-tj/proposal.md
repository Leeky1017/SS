# Proposal: issue-295-phase-5-9-ti-tj

## Why
Phase 4.9 made TI/TJ runnable and contract-compliant; Phase 5.9 upgrades content quality with survival/multivariate best practices, bilingual guidance, and stronger guardrails (no silent failure).

## What Changes
- Add a standardized best-practice review record block to each TI01–TI11 + TJ01–TJ06 do-template.
- Strengthen validation and diagnostics for common survival/multivariate pitfalls (PH assumptions, competing risks, small event counts, convergence).
- Prefer Stata built-ins; keep SSC deps only when no built-in alternative exists (documented in-template).

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/spec.md`
- Affected code: `assets/stata_do_library/do/TI*.do`, `assets/stata_do_library/do/TJ*.do`
- Breaking change: NO
- User benefit: more reliable and interpretable survival + multivariate analyses with explicit diagnostics and bilingual guidance
