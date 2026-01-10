# Proposal: issue-272-p4-11-accounting-tl

## Why
Run TL01–TL15 templates on Stata 18 smoke-suite fixtures with 0 failed runs, and normalize anchors/style so downstream log parsing and evidence capture is reliable.

## What Changes
- Add a dedicated TL smoke-suite manifest + common fixture.
- Fix TL01–TL15 runtime blockers (brace syntax, BOM, fragile model fit) and normalize anchors to pipe-delimited `SS_EVENT|k=v`.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.11__accounting-TL.md`
- Affected code: `assets/stata_do_library/do/TL01_*.do` … `TL15_*.do`, `assets/stata_do_library/smoke_suite/manifest.issue-272.tl01-tl15.1.0.json`
- Breaking change: NO
- User benefit: TL templates run end-to-end in Stata 18 harness with consistent, machine-parseable anchors.
