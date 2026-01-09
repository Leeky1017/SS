# Proposal: issue-263-p58-timeseries-th

## Why
Phase 5.8 requires best-practice content upgrades for the Time Series advanced module (TH*), including bilingual guidance, stronger guardrails, and reducing SSC dependency surface where feasible.

## What Changes
- Add best-practice review records to TH templates (TH01–TH04, TH06–TH09, TH11–TH15; repo truth: TH05/TH10 were deleted earlier).
- Strengthen time-series preflight checks (tsset assumptions, ordering/gaps/small-sample warnings) and convert “silent skip” paths into explicit `warn/fail` with structured anchors.
- Replace SSC dependency `asreg` in TH14 with Stata built-in rolling regression; keep unavoidable SSC deps with explicit justification.

## Impact
- Affected specs:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5.8__timeseries-TH.md`
- Affected code/data assets:
  - `assets/stata_do_library/do/TH*.do`
  - `assets/stata_do_library/do/meta/TH*.meta.json` (as needed for dependency updates)
- Breaking change: NO (behavior tightened via explicit guardrails and clearer failure modes)
- User benefit: More reliable time-series runs, clearer interpretation guidance, fewer external dependencies.
