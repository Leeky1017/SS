# Proposal: issue-273-p4-12-medical-tm

## Why
Make TM01–TM15 templates runnable in the Stata 18 smoke-suite harness with 0 `failed`, contract-compliant anchors, and consistent style.

## What Changes
- Add a TM01–TM15 smoke-suite manifest + fixture dataset.
- Fix runtime errors in TM01–TM15 and normalize anchors to pipe-delimited `SS_*|k=v`.
- Make SSC-only commands explicit deps and emit `SS_DEP_*` anchors when missing.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.12__medical-TM.md`
- Affected code: `assets/stata_do_library/do/TM*.do`, `assets/stata_do_library/smoke_suite/manifest.issue-273.tm01-tm15.1.0.json`, `assets/stata_do_library/fixtures/TM_common/sample_data.csv`
- Breaking change: NO
- User benefit: TM templates are smoke-suite verifiable and produce machine-parseable evidence.
