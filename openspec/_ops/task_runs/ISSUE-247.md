# ISSUE-247
- Issue: #247
- Branch: task/247-p5-7-causal-tg
- PR: <fill-after-created>

## Goal
- Phase 5.7 TG01–TG25: content enhancement (best practices + SSC→Stata18 native where feasible + stronger error handling + bilingual comments).

## Status
- CURRENT: TG01–TG25 updates implemented; validations green; ready to open PR.

## Next Actions
- [x] Replace SSC where feasible (PSM/IV/DID first) and justify exceptions (RDD/SCM/MTE).
- [x] Add per-template Phase 5.7 best-practice review blocks (TG01–TG25).
- [x] Run do-lint + ruff + pytest and link outputs here.

## Decisions Made
- <date>: <decision> → <reason>

## Errors Encountered
- <date>: <error> → <resolution/next>

## Runs
### 2026-01-09 00:00 worktree
- Command:
  - `scripts/agent_controlplane_sync.sh && scripts/agent_worktree_setup.sh "247" "p5-7-causal-tg"`
- Key output:
  - `Worktree created: .worktrees/issue-247-p5-7-causal-tg`
- Evidence:
  - `.worktrees/issue-247-p5-7-causal-tg`

### 2026-01-09 00:40 do-lint
- Command:
  - `for f in assets/stata_do_library/do/TG*.do; do python3 assets/stata_do_library/DO_LINT_RULES.py --file "$f"; done`
- Key output:
  - `RESULT: [OK] PASSED` (TG01–TG25)
- Evidence:
  - `assets/stata_do_library/do/TG02_psm_match.do`

### 2026-01-09 00:41 ruff
- Command:
  - `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`
- Evidence:
  - `pyproject.toml`

### 2026-01-09 00:41 pytest
- Command:
  - `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output:
  - `159 passed, 5 skipped`
- Evidence:
  - `tests/test_do_library_meta_schema.py`
