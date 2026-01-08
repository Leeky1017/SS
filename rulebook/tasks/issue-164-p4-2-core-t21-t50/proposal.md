# Proposal: issue-164-p4-2-core-t21-t50

## Why
Phase 4 needs Stata 18 runtime evidence that core templates `T21`–`T50` run without errors and emit contract-compliant anchors.

## What Changes
- Add a phase-scoped smoke-suite manifest to batch-run `T21`–`T50` with fixtures.
- Fix any runtime failures in the affected `.do` templates.
- Normalize legacy `SS_*:` anchors to the pipe-delimited contract format.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.2__core-T21-T50.md`
- Affected code: `assets/stata_do_library/do/T21_*.do` … `assets/stata_do_library/do/T50_*.do`, plus a new smoke-suite manifest
- Breaking change: NO (template outputs and IDs unchanged; anchor formatting is normalized)
- User benefit: repeatable Stata 18 audit evidence and fewer template runtime failures
