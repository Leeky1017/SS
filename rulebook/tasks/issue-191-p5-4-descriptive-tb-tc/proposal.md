# Proposal: issue-191-p5-4-descriptive-tb-tc

## Why
Phase 5.4 upgrades TB* (descriptive) and TC* (hypothesis testing) templates beyond “runnable”: better default outputs, fewer external dependencies, and clearer failure modes improve reliability for the Stata runner and help the LLM generate interpretable, auditable results.

## What Changes
- Add per-template best-practice review records and bilingual comments (中英文注释) for key steps + interpretation hints.
- Replace/relax SSC dependencies where feasible by using Stata 18 built-ins and graceful fallbacks (warn instead of hard fail).
- Strengthen input validation and error handling to avoid silent failure and to emit explicit `SS_RC|...` records.
- Align selected template `meta.json` (deps/inputs) with implemented behavior where inconsistent.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-5.4__descriptive-TB-TC.md`
- Affected code: `assets/stata_do_library/do/TB02_*.do` … `TB10_*.do`, `assets/stata_do_library/do/TC01_*.do` … `TC10_*.do`, related `assets/stata_do_library/do/meta/*.meta.json`
- Breaking change: NO (template IDs/files unchanged; outputs remain declared)
- User benefit: More robust descriptive/hypothesis-testing runs with clearer diagnostics and fewer environment-specific failures.

