# Notes: issue-273-p4-12-medical-tm

## Decisions
- Prefer smoke-suite “0 failed” while explicitly surfacing missing SSC commands via `SS_DEP_CHECK|...|status=missing` + `SS_DEP_MISSING|pkg=...`.
- Replace non-portable / missing commands (e.g., `icc`) with built-in alternatives when feasible.

## Findings
- Missing deps in a clean Stata environment are expected for some TM templates:
  - `diagt` (TM02)
  - `metan` (TM06)
  - `metafunnel` (TM07)

## Evidence pointers
- Smoke suite report: `/tmp/ss-smoke-suite-issue273-tm.json`
