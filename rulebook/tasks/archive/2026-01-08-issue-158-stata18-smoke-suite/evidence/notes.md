# Notes: issue-158-stata18-smoke-suite

## Decisions
- Use a versioned JSON manifest + JSON Schema under `assets/stata_do_library/` so CI can validate without Stata.
- Implement `ss run-smoke-suite` as a local-only harness that reuses existing template runner artifacts, and emits a single structured JSON report.

## Later
- Optional: add an opt-in flag to auto-install missing SSC deps (via `ssc install`) for local runs.
- Optional: extend fixtures contract to cover multi-dataset inputs (beyond `data.csv`).

