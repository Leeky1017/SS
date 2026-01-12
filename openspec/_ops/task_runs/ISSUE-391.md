# ISSUE-391
- Issue: #391
- Branch: task/391-deploy-ready-r031
- PR: https://github.com/Leeky1017/SS/pull/400

## Plan
- Add `output_formats` request + defaults.
- Implement OutputFormatterService and worker hook.
- Patch template deps, add tests, and ship PR.

## Runs
### 2026-01-12 Bootstrap (spec-first)
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "391" "deploy-ready-r031"`
  - `rulebook task create issue-391-deploy-ready-r031`
  - `rulebook task validate issue-391-deploy-ready-r031`
- Key output:
  - `Worktree: .worktrees/issue-391-deploy-ready-r031`
  - `Branch: task/391-deploy-ready-r031`
  - `Task: rulebook/tasks/issue-391-deploy-ready-r031/`
- Evidence:
  - `openspec/specs/ss-deployment-docker-readiness/task_cards/remediation__DEPLOY-READY-R031.md`
  - `rulebook/tasks/issue-391-deploy-ready-r031/proposal.md`
  - `rulebook/tasks/issue-391-deploy-ready-r031/tasks.md`

### 2026-01-12 Audit meta deps (putdocx mismatch resolved)
- Command: `python3 scripts/audit_do_template_output_formats.py`
- Key output:
  - `docx_outputs_templates=15 docx_templates_with_dep_putdocx=15 docx_templates_missing_dep_putdocx=0`
  - `pdf_outputs_templates=1 pdf_report_templates=0 pdf_figure_templates=1`

### 2026-01-12 Local checks (ruff + pytest)
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -U pip`
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `188 passed, 5 skipped`

### 2026-01-12 Fix mypy (reportlab stubs) + rerun checks
- Command:
  - `.venv/bin/python -m pip install -e '.[dev]'`
  - `.venv/bin/mypy`
  - `.venv/bin/pytest -q`
- Key output:
  - `Success: no issues found in 175 source files`
  - `194 passed, 5 skipped in 9.16s`
