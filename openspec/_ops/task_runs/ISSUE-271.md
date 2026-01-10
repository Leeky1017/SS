# ISSUE-271

- Issue: #271
- Parent: #125
- Branch: task/271-phase-4-9-survival-multivariate-ti-tj
- PR: <fill-after-created>

## Goal
- Make TI/TJ survival + multivariate templates run on Stata 18 with fixtures, and emit contract-compliant anchors.

## Plan
- Add TI/TJ smoke-suite manifest (fixtures + params + deps).
- Run Stata 18 harness; fix failures to 0 failed within scope.
- Normalize anchors to `SS_EVENT|k=v` and unify style within TI/TJ templates.

## Status
- CURRENT: Changes committed + pushed; run preflight, open PR, and enable auto-merge.

## Next Actions
- [x] Run `ruff` + `pytest` + `openspec validate` and record outputs.
- [x] Commit changes with `(#271)` and push branch.
- [ ] Run PR preflight and open PR with `Closes #271` + enable auto-merge.

## Decisions Made
- (append as made)

## Errors Encountered
- (append as encountered)

## Runs

### 2026-01-10 09:33 setup (issue/worktree/venv)
- Command:
  - `gh issue create -t "[PHASE-4.9] TI/TJ: Stata 18 audit + anchor normalization (TI01-TI11, TJ01-TJ06)" -b "<body>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "271" "phase-4-9-survival-multivariate-ti-tj"`
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
- Key output:
  - `Issue: https://github.com/Leeky1017/SS/issues/271`
  - `Worktree created: .worktrees/issue-271-phase-4-9-survival-multivariate-ti-tj`
  - `Successfully installed ... ss-0.0.0`
- Evidence:
  - `.venv/`

### 2026-01-10 09:46 smoke suite (initial) — failures triaged
- Command: `. .venv/bin/activate && python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-271.ti01-ti11.tj01-tj06.1.0.json --report-path rulebook/tasks/issue-271-phase-4-9-survival-multivariate-ti-tj/evidence/smoke_suite_report.issue-271.rerun1.json --timeout-seconds 600`
- Key output: `summary {'failed': 9, 'missing_deps': 1, 'passed': 7}` (root causes: r(198) brace blocks; r(198) missing id() for stsplit/mds; r(430) non-convergence; r(693) missing graph)
- Evidence: `rulebook/tasks/issue-271-phase-4-9-survival-multivariate-ti-tj/evidence/smoke_suite_report.issue-271.rerun1.json`

### 2026-01-10 09:59 smoke suite (post-fixes) — 0 failed
- Command: `. .venv/bin/activate && python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-271.ti01-ti11.tj01-tj06.1.0.json --report-path rulebook/tasks/issue-271-phase-4-9-survival-multivariate-ti-tj/evidence/smoke_suite_report.issue-271.rerun2.json --timeout-seconds 600`
- Key output: `summary {'missing_deps': 1, 'passed': 16}` (missing: `stcure`)
- Evidence: `rulebook/tasks/issue-271-phase-4-9-survival-multivariate-ti-tj/evidence/smoke_suite_report.issue-271.rerun2.json`

### 2026-01-10 10:17 smoke suite (post-anchors) — 0 failed
- Command: `. .venv/bin/activate && python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-271.ti01-ti11.tj01-tj06.1.0.json --report-path rulebook/tasks/issue-271-phase-4-9-survival-multivariate-ti-tj/evidence/smoke_suite_report.issue-271.post-anchors.json --timeout-seconds 600`
- Key output: `summary {'missing_deps': 1, 'passed': 16}` (anchors normalized + ss_fail; still only missing: `stcure`)
- Evidence: `rulebook/tasks/issue-271-phase-4-9-survival-multivariate-ti-tj/evidence/smoke_suite_report.issue-271.post-anchors.json`

### 2026-01-10 10:20 ruff — ok
- Command: `. .venv/bin/activate && ruff check .`
- Key output: `All checks passed!`
- Evidence: n/a

### 2026-01-10 10:20 pytest — ok
- Command: `. .venv/bin/activate && pytest -q`
- Key output: `162 passed, 5 skipped in 9.17s`
- Evidence: n/a

### 2026-01-10 10:21 openspec validate — ok
- Command: `. .venv/bin/activate && openspec validate --specs --strict --no-interactive`
- Key output: `Totals: 25 passed, 0 failed (25 items)`
- Evidence: n/a

### 2026-01-10 10:23 commit + push
- Command:
  - `git commit -m "fix: audit TI/TJ templates (Stata 18 + anchors) (#271)"`
  - `git push -u origin HEAD`
- Key output:
  - `[task/271-phase-4-9-survival-multivariate-ti-tj 8a6d90d] fix: audit TI/TJ templates (Stata 18 + anchors) (#271)`
  - `* [new branch]      HEAD -> task/271-phase-4-9-survival-multivariate-ti-tj`
- Evidence: n/a
