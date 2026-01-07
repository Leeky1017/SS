# ISSUE-155

- Issue: #155
- Parent: #125
- Branch: task/155-phase-2-deduplicate-and-normalize-placeholders
- PR: https://github.com/Leeky1017/SS/pull/156

## Goal
- Deduplicate first-wave exact duplicates in `assets/stata_do_library/do/` and standardize high-frequency placeholders across remaining templates.

## Status
- CURRENT: Set up task scaffolding; ready to implement dedup + placeholder normalization.

## Next Actions
- [ ] Delete redundant templates (TD07/TD08/TD09/TD11/TU15/TH10/TH05/TF13/TB01) and keep canonical ones.
- [ ] Normalize placeholders (`__DEPVAR__`, `__INDEPVARS__`, `__TIME_VAR__`) across remaining templates/meta.
- [ ] Regenerate `assets/stata_do_library/DO_LIBRARY_INDEX.json` and tighten placeholder lint gate.

## Runs
### 2026-01-07 issue + worktree
- Command:
  - `gh issue create -t "[ROUND-00-LIB-A] DO-TPL-P2: deduplicate templates + normalize placeholders" -b "..."`
  - `scripts/agent_worktree_setup.sh "155" "phase-2-deduplicate-and-normalize-placeholders"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/155`
  - `Worktree created: .worktrees/issue-155-phase-2-deduplicate-and-normalize-placeholders`

### 2026-01-07 dedup delete-first-wave
- Command:
  - `rm assets/stata_do_library/do/{TB01_group_desc_table,TD07_lasso,TD08_ridge,TD09_elastic_net,TD11_spline,TF13_xtfmb,TH05_garch,TH10_vec,TU15_mi_impute}.do`
  - `rm assets/stata_do_library/do/meta/{TB01_group_desc_table,TD07_lasso,TD08_ridge,TD09_elastic_net,TD11_spline,TF13_xtfmb,TH05_garch,TH10_vec,TU15_mi_impute}.meta.json`
  - `rm assets/stata_do_library/docs/{TB01_group_desc_table,TD07_lasso,TD08_ridge,TD09_elastic_net,TD11_spline,TF13_xtfmb,TH05_garch,TH10_vec,TU15_mi_impute}.md`
- Key output:
  - Removed 9 redundant templates (do + meta) and their per-template docs

### 2026-01-07 placeholder normalization
- Command:
  - `python3 - <<'PY' ... PY` (replace `__DEP_VAR__`→`__DEPVAR__`, `__INDEP_VARS__`→`__INDEPVARS__`, `__TIMEVAR__`→`__TIME_VAR__`)
  - `rg -n "__DEP_VAR__|__INDEP_VARS__|__TIMEVAR__" assets/stata_do_library` (expect no matches)
- Key output:
  - Updated 225 files under `assets/stata_do_library/` to canonical placeholder forms

### 2026-01-07 regenerate index + family summary
- Command:
  - `python3 scripts/regenerate_do_library_index.py`
- Key output:
  - `assets/stata_do_library/DO_LIBRARY_INDEX.json`: `total_tasks=310` and no stale IDs
  - `assets/stata_do_library/taxonomy/family_summary/1.0.json` regenerated to match index

### 2026-01-07 local verification
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `ruff`: All checks passed
  - `pytest`: 120 passed, 5 skipped

### 2026-01-07 pr preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-07 task card closeout
- Command:
  - Update Phase 2 task card acceptance checklist + completion section
- Key output:
  - https://github.com/Leeky1017/SS/pull/157
