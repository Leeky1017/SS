# Notes: issue-191-p5-4-descriptive-tb-tc

## Findings
- TB06/TB07/TB09 previously hard-required SSC plotting helpers (`heatplot`, `vioplot`, `spineplot`). Prefer removing hard dependencies by adding built-in fallbacks that still produce the declared `fig_*.png` output (quality may degrade, but the run should not fail).
- TB02-TB04 meta previously declared `data.dta` required but smoke-suite fixtures and templates load `data.csv`; align meta inputs to avoid upstream “missing input” failures.

## Decisions
- Prefer “warn + degrade gracefully” over “hard fail” for optional visualization helpers when a built-in approximation exists.

## Later
- Consider standardizing inputs across the whole library (`data.csv` as required; `data.dta` optional) and regenerating fixtures/manifests accordingly (out of scope for #191).

