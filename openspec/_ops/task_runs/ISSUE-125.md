# ISSUE-125

- Issue: #125
- Branch: task/125-do-template-optimization
- PR: https://github.com/Leeky1017/SS/pull/130

## Plan
- Inventory templates + meta/index for taxonomy, duplicates, and drift
- Write optimization requirements/spec + strategy README + prioritized task cards
- Open PR with required checks + auto-merge

## Runs
### 2026-01-07 init
- Command:
  - `gh issue create -t "[ROUND-00-DOC-A] DO-LIB-OPT: do template optimization spec" -b "<context + acceptance>"`
  - `scripts/agent_worktree_setup.sh "125" "do-template-optimization"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/125`
  - `Worktree created: .worktrees/issue-125-do-template-optimization`

### 2026-01-07 inventory
- Command:
  - `find assets/stata_do_library/do -type f -name '*.do' | wc -l`
  - `find assets/stata_do_library/do/meta -type f -name '*.meta.json' | wc -l`
  - `python3 - <<'PY' ... PY` (modules/families/levels, placeholder/meta consistency, duplicate signals)
- Key output:
  - Templates: 319 do-files + 319 meta.json
  - Meta placeholders <-> meta.parameters: 0 mismatches across 319
  - Modules: 21 (A-U); levels: L0=109, L1=104, L2=105, L3=1
  - Exact-duplicate signals (meta): elastic_net (TD09/TS03), spline (TD11/TU12), mi_impute (TA03/TU15), etc.

### 2026-01-07 docs review
- Command:
  - `sed -n '1,240p' assets/stata_do_library/README.md`
  - `python3 -c 'import json; ...' assets/stata_do_library/DO_LIBRARY_INDEX.json`
  - `sed -n '1,120p' assets/stata_do_library/CAPABILITY_MANIFEST.json`
  - `sed -n '1,240p' openspec/specs/ss-do-template-library/spec.md`
- Key output:
  - `DO_LIBRARY_INDEX.json` has drift: tasks are all `PROD_READY` but `compliance_summary.prod_ready` is `50`
  - `CAPABILITY_MANIFEST.json` hardcodes Windows `ado_path` (`C:\\SS_ADO\\plus`)
  - Some library docs/contracts still reference legacy `tasks/` paths (needs alignment)

### 2026-01-07 spec drafted
- Evidence:
  - `openspec/specs/ss-do-template-optimization/spec.md`
  - `openspec/specs/ss-do-template-optimization/README.md`
  - `openspec/specs/ss-do-template-optimization/task_cards/`

### 2026-01-07 local verification
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `ruff`: All checks passed
  - `pytest`: 95 passed, 5 skipped

### 2026-01-07 pr preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-07 pr opened
- Command:
  - `gh pr create --title "docs: do-template optimization spec (#125)" --body "Closes #125 ..."`
- Key output:
  - `https://github.com/Leeky1017/SS/pull/130`

### 2026-01-07 auto-merge enabled
- Command:
  - `gh pr merge --auto --squash 130`
- Key output:
  - PR will auto-merge when required checks pass
