# Tasks: issue-364-phase-5-15-bayes-ml-text-viz-tr-tu

## Package A (TR* + TS*)
- Add Bayes best-practice guidance + diagnostics (priors, ESS/diagnostics, convergence warnings).
- Add ML best practices (CV hygiene, model selection notes, leakage avoidance) + stronger validations.
- Remove/update SSC deps in meta where no longer used; justify any remaining SSC.

## Package B (TT* + TU*)
- Improve text preprocessing + sentiment robustness; strengthen input checks.
- Improve visualization standards (graph settings, export consistency) + stronger validations.
- Remove/update SSC deps in meta where no longer used; justify any remaining SSC.

## Verification
- `ruff check .`
- `pytest -q`

