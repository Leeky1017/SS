# ISSUE-363
- Issue: #363
- Branch: task/363-phase-5-14-panel-hlm-tp-tq
- PR: <fill-after-created>

## Goal
- Phase 5.14 TP01–TP15 + TQ01–TQ12: content enhancement (best practices + SSC→Stata18 native where feasible + stronger error handling + bilingual comments).

## Plan
- Add Phase 5.14 best-practice review records (TP/TQ).
- Replace SSC deps where feasible; justify exceptions.
- Strengthen validation/diagnostics and error-handling.

## Runs
### 2026-01-12 12:10 Bootstrap (spec-first)
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "363" "phase-5-14-panel-hlm-tp-tq"`
  - `rulebook task create issue-363-phase-5-14-panel-hlm-tp-tq`
  - `rulebook task validate issue-363-phase-5-14-panel-hlm-tp-tq`
- Key output:
  - `Worktree: .worktrees/issue-363-phase-5-14-panel-hlm-tp-tq`
  - `Task: rulebook/tasks/issue-363-phase-5-14-panel-hlm-tp-tq/`
- Evidence:
  - `openspec/specs/ss-do-template-optimization/task_cards/phase-5.14__panel-hlm-TP-TQ.md`
  - `rulebook/tasks/issue-363-phase-5-14-panel-hlm-tp-tq/proposal.md`
  - `rulebook/tasks/issue-363-phase-5-14-panel-hlm-tp-tq/tasks.md`
  - `rulebook/tasks/issue-363-phase-5-14-panel-hlm-tp-tq/specs/ss-do-template-optimization/spec.md`

### 2026-01-12 13:02 Review record coverage (TP/TQ)
- Command:
  - `ls assets/stata_do_library/do/TP*.do | wc -l`
  - `ls assets/stata_do_library/do/TQ*.do | wc -l`
  - `for f in assets/stata_do_library/do/TP*.do assets/stata_do_library/do/TQ*.do; do rg -n "SS_BP_REVIEW\\|issue=363" "$f" >/dev/null || echo "MISSING $f"; done`
- Key output:
  - `15`
  - `12`
  - `(no MISSING lines)`
- Evidence:
  - `assets/stata_do_library/do/TP*.do`
  - `assets/stata_do_library/do/TQ*.do`

### 2026-01-12 13:04 Do-lint (TP/TQ only)
- Command:
  - `fail=0; total=0; for f in assets/stata_do_library/do/TP*.do assets/stata_do_library/do/TQ*.do; do total=$((total+1)); out=$(python3 assets/stata_do_library/DO_LINT_RULES.py --file "$f" 2>&1); echo "$out" | rg -q "RESULT: \\[X\\] FAILED" && { echo "FAILED: $f"; fail=$((fail+1)); }; done; echo "DO_LINT_SUMMARY total=$total failed=$fail"`
- Key output:
  - `DO_LINT_SUMMARY total=27 failed=0`

### 2026-01-12 13:06 Local checks (ruff + pytest)
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -U pip`
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `184 passed, 5 skipped in 10.29s`
