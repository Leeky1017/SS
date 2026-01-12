# ISSUE-415
- Issue: #415
- Branch: task/415-ci-coverage-gate
- PR: <fill-after-created>

## Goal
- Prevent coverage regressions by gating CI at a safe baseline (`--cov-fail-under=75`).

## Status
- CURRENT: Creating Rulebook artifacts + implementing CI coverage gate.

## Next Actions
- [ ] Fill Rulebook `proposal.md`/`tasks.md` + add spec delta.
- [ ] Add `pytest-cov` to `.[dev]` and enforce coverage in `ci`/`merge-serial`.
- [ ] Run `ruff check .` and `pytest -q --cov=src --cov-fail-under=75`, then open PR + auto-merge.

## Decisions Made
- 2026-01-12 Create worktree before adding task files, to keep controlplane clean for `scripts/agent_controlplane_sync.sh`.

## Errors Encountered
- None.

## Runs
### 2026-01-12 Create Issue
- Command:
  - `gh issue create -t "[CI] Coverage gate: enforce 75% baseline" -b "<body>"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/415`
- Evidence:
  - N/A

### 2026-01-12 Create worktree
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "415" "ci-coverage-gate"`
- Key output:
  - `Worktree created: .worktrees/issue-415-ci-coverage-gate`
  - `Branch: task/415-ci-coverage-gate`
- Evidence:
  - N/A

### 2026-01-12 Create Rulebook task (spec-first)
- Command:
  - `rulebook task create issue-415-ci-coverage-gate`
  - `rulebook task validate issue-415-ci-coverage-gate`
- Key output:
  - `Task issue-415-ci-coverage-gate created successfully`
  - `Task issue-415-ci-coverage-gate is valid`
- Evidence:
  - `rulebook/tasks/issue-415-ci-coverage-gate/`

### 2026-01-12 Implement CI coverage gate (75%)
- Change:
  - Add `pytest-cov` to `.[dev]`.
  - Update `ci` + `merge-serial` workflows to run pytest with coverage and `--cov-fail-under=75`.
  - Record the baseline coverage gate in OpenSpec testing strategy.
- Evidence:
  - `pyproject.toml`
  - `.github/workflows/ci.yml`
  - `.github/workflows/merge-serial.yml`
  - `openspec/specs/ss-testing-strategy/spec.md`
  - `openspec/specs/ss-testing-strategy/README.md`

### 2026-01-12 Local tooling setup
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install --upgrade pip`
  - `.venv/bin/pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... pytest-cov ...`
- Evidence:
  - `.venv/`

### 2026-01-12 Lint
- Command:
  - `.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`
- Evidence:
  - N/A

### 2026-01-12 Type check
- Command:
  - `.venv/bin/mypy`
- Key output:
  - `Success: no issues found in 175 source files`
- Evidence:
  - N/A

### 2026-01-12 Tests + coverage gate
- Command:
  - `.venv/bin/pytest -q --cov=src --cov-report=term-missing --cov-fail-under=75`
- Key output:
  - `196 passed, 5 skipped`
  - `Required test coverage of 75% reached. Total coverage: 78.60%`
- Evidence:
  - N/A

### 2026-01-12 OpenSpec validate (strict)
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 29 passed, 0 failed (29 items)`
- Evidence:
  - N/A
