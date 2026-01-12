# ISSUE-364
- Issue: #364
- Branch: task/364-phase-5-15-bayes-ml-text-viz-tr-tu
- PR: https://github.com/Leeky1017/SS/pull/373

## Plan
- Add best-practice upgrades (Bayes/ML/Text/Viz)
- Remove/justify SSC deps and strengthen errors
- Run ruff/pytest and ship PR

## Runs

### 2026-01-12 13:15 template-updates
- Command: `rg -n "local\\s+[A-Za-z0-9_]+\\s*=\\s*__[^\\s\\\"]+__" assets/stata_do_library/do/{TR*,TS*,TT*,TU*}.do`
- Key output: `no matches` (optional numeric placeholders now parsed safely)
- Evidence: `assets/stata_do_library/do/TU10_coef_plot.do`, `assets/stata_do_library/do/TU11_rifhdreg.do`, `assets/stata_do_library/do/TU12_spline.do`, `assets/stata_do_library/do/TU13_lpoly.do`, `assets/stata_do_library/do/TU14_npregress.do`

### 2026-01-12 13:15 ruff
- Command: `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output: `All checks passed!`

### 2026-01-12 13:15 pytest
- Command: `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output: `184 passed, 5 skipped in 11.09s`

### 2026-01-12 13:15 preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`

### 2026-01-12 13:15 pr-create
- Command: `gh pr create --base main --head task/364-phase-5-15-bayes-ml-text-viz-tr-tu ...`
- Key output: `https://github.com/Leeky1017/SS/pull/373`
