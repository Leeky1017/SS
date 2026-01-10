# ISSUE-284
- Issue: #284
- Branch: task/284-p5-12-medical-tm
- PR: <fill-after-created>

## Goal
- Enhance TM01–TM15 (Medical/Biostats): best practices, SSC deps replacement where feasible, stronger error handling (`SS_RC`), and bilingual comments; keep evidence auditable.

## Status
- CURRENT: Worktree setup and baseline review.

## Next Actions
- [ ] Create Rulebook task skeleton (proposal/tasks/notes)
- [ ] Audit TM01–TM15 for SSC deps + weak error handling
- [ ] Apply template upgrades + run Do-library lint

## Decisions Made
- 2026-01-10 Replace SSC `metan`/`metafunnel` with Stata 18 built-in `meta` suite to remove SSC dependency for TM06/TM07.

## Errors Encountered
- 2026-01-10 `scripts/agent_controlplane_sync.sh` failed due to dirty working tree (untracked Rulebook task dirs) → removed and recreated inside worktree branches.

## Runs
### 2026-01-10 00:00 Create GitHub Issue
- Command:
  - `gh issue create -t "[PHASE-5.12] TM: Medical/Biostats template enhancement (TM01–TM15)" -b "<...>"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/284`
- Evidence:
  - Task card: `openspec/specs/ss-do-template-optimization/task_cards/phase-5.12__medical-TM.md`

### 2026-01-10 00:00 Controlplane sync + worktree setup
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 284 p5-12-medical-tm`
- Key output:
  - `Worktree created: .worktrees/issue-284-p5-12-medical-tm`
  - `Branch: task/284-p5-12-medical-tm`
- Evidence:
  - `.worktrees/issue-284-p5-12-medical-tm`

### 2026-01-10 00:00 TM template upgrades + lint
- Command:
  - `rg -n "source=ssc" assets/stata_do_library/do/TM*.do`
  - `for f in assets/stata_do_library/do/TM*.do; do python3 assets/stata_do_library/DO_LINT_RULES.py --file "$f" --strict >/dev/null; done`
- Key output:
  - `no matches for source=ssc`
  - `TM lint OK`
- Evidence:
  - Updated templates: `assets/stata_do_library/do/TM01_roc_analysis.do` … `TM15_sample_size_clinical.do`
  - Updated meta: `assets/stata_do_library/do/meta/TM02_diagnostic_test.meta.json`, `TM06_meta_analysis.meta.json`, `TM07_funnel_plot.meta.json`

### 2026-01-10 00:00 Fix smoke-suite manifest deps + tests
- Command:
  - `/home/leeky/work/SS/.venv/bin/python -m pytest -q`
  - `apply_patch (update assets/stata_do_library/smoke_suite/manifest.issue-273.tm01-tm15.1.0.json: TM06/TM07 deps)`
  - `/home/leeky/work/SS/.venv/bin/python -m pytest -q`
- Key output:
  - `FAILED tests/test_smoke_suite_manifest.py::... TM06 dependency not declared in meta: metan:ssc`
  - `162 passed, 5 skipped`
- Evidence:
  - `assets/stata_do_library/smoke_suite/manifest.issue-273.tm01-tm15.1.0.json`
