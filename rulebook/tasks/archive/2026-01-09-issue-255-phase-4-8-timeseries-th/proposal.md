# Proposal: issue-255-phase-4-8-timeseries-th

## Why
Phase 4.8 requires Stata 18 runtime evidence for TH templates and removal of legacy anchor variants; the current TH templates fail the smoke suite and emit non-canonical anchors.

## What Changes
- Add a dedicated TH smoke-suite manifest (fixtures + params).
- Fix TH01–TH04, TH06–TH09, TH11–TH15 runtime issues and normalize anchors to `SS_EVENT|k=v`.
- Add defensive time-series validation (timevar existence, fallback `tsset` index) and wrap brittle commands to avoid hard failures on tiny fixtures.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.8__timeseries-TH.md`
- Affected code:
  - `assets/stata_do_library/do/TH*.do`
  - `assets/stata_do_library/smoke_suite/manifest.issue-255.th01-th15.1.0.json`
  - `openspec/_ops/task_runs/ISSUE-255.md`
- Breaking change: NO
- User benefit: TH templates run under Stata 18 harness with auditable, contract-compliant anchors (missing SSC deps are reported as `missing_deps`, not `failed`).
