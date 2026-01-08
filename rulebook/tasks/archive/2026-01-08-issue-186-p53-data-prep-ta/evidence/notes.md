# Notes: issue-186-p53-data-prep-ta

## Shared decisions

- Prefer Stata 18 built-in tooling (`misstable`, `summarize, detail`, `codebook`, `duplicates`) over SSC utilities for profiling.
- Default policy: fail fast on missing required inputs (dataset, key variables); warn (with `SS_RC|severity=warn`) for non-fatal diagnostics.

