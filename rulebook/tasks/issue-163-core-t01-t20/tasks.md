## 1. Harness + Evidence
- [x] 1.1 Create Phase-4.1 smoke-suite manifest (T01–T20) with fixtures + required params
- [x] 1.2 Run Stata 18 harness and save JSON report as evidence (WSL env reports `stata_unavailable`)

## 2. Template fixes (T01–T20)
- [x] 2.1 Runtime fixes (vars/files/types/empty sample/collinearity) with explicit warn/fail + SS_RC
- [x] 2.2 Anchor unification: replace all legacy `SS_*:...` with `SS_EVENT|k=v`
- [x] 2.3 Style unification: headers/steps/naming/seeds; dependency checks fail fast when missing

## 3. Validation + Delivery
- [x] 3.1 Run `python3 assets/stata_do_library/DO_LINT_RULES.py --path assets/stata_do_library/do/` (sanity)
- [x] 3.2 Run `ruff check .` and `pytest -q`
- [ ] 3.3 Run `scripts/agent_pr_preflight.sh`, open PR, enable auto-merge, update run log with evidence links
