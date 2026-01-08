# Proposal: issue-163-core-t01-t20

## Why
Phase 4 requires a real Stata 18 audit of the template library. The core set (T01–T20) is foundational: if these fail or emit non-compliant anchors, downstream composition and evidence tooling cannot be trusted.

## What Changes
- Add a dedicated Stata 18 batch manifest for templates `T01`–`T20` using their fixtures + minimal required params.
- Fix template runtime failures (missing vars/files, type mismatches, empty samples, convergence/collinearity) with explicit `warn/fail` behavior.
- Normalize anchors by removing legacy `SS_*:...` variants and using pipe-delimited `SS_EVENT|k=v`.
- Normalize template style: headers, step anchors, deterministic randomness (`set seed ...` when applicable), and consistent dependency fast-fail for SSC packages.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.1__core-T01-T20.md`
- Affected code/assets: `assets/stata_do_library/do/T01_*.do` … `T20_*.do`, plus smoke-suite manifest and tests
- Breaking change: NO (template behavior becomes stricter/cleaner; IDs unchanged)
- User benefit: templates are runnable/auditable on Stata 18 with consistent machine-parsable anchors and reproducible evidence.

