# Proposal: issue-193-p5-1-core-t01-t20

## Why
Phase 4.1 made core templates runnable, but Phase 5.1 is needed to upgrade them to production-grade analysis: clearer best-practice decisions, fewer SSC deps, stronger warn/fail handling, and bilingual comments for auditability.

## What Changes
- Add a per-template best-practice review record (decision + rationale) for T01–T20.
- Prefer Stata 18 native output tooling for tables (notably replacing `estout/esttab` with `putdocx` where used).
- Tighten systematic input checks and make warn/fail decisions explicit with `SS_RC` anchors.
- Add bilingual comments (中英文注释) for key steps (load/validate/analyze/export).

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-5.1__core-T01-T20.md`
- Affected code: `assets/stata_do_library/do/T01_*.do` … `assets/stata_do_library/do/T20_*.do`, `assets/stata_do_library/do/meta/T01_*.meta.json` … `assets/stata_do_library/do/meta/T20_*.meta.json`
- Breaking change: NO (templates remain same IDs; outputs may be upgraded from `.rtf` to `.docx` where applicable)
- User benefit: More maintainable templates with fewer external deps and more auditable outputs.
