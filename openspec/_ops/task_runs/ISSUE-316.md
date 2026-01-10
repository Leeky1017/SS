# ISSUE-316
- Issue: #316 https://github.com/Leeky1017/SS/issues/316
- Branch: task/316-prod-e2e-r041-remove-stub-llm
- PR: <fill>

## Goal
- Remove runtime support for `SS_LLM_PROVIDER=stub` and any `StubLLMClient` wiring; require explicit real LLM provider configuration; keep tests using injected fakes only.

## Status
- CURRENT: Local validation green; preparing PR.

## Next Actions
- [x] Remove runtime stub provider branch and StubLLMClient wiring.
- [x] Make `SS_LLM_PROVIDER` explicit (no stub default) and reject `SS_LLM_PROVIDER=stub` with stable error code.
- [x] Update tests to use injected `tests/**` fake LLM.
- [x] Run `ruff check .` and `pytest -q`.
- [ ] Run `scripts/agent_pr_preflight.sh`, open PR, enable auto-merge, verify `MERGED`.

## Decisions Made
- 2026-01-10: Runtime stub LLM is removed; tests use injected fakes in `tests/**` only.

## Errors Encountered
- 2026-01-10: `ruff check .` failed with `command not found` (no dev deps) → created a local venv and installed `.[dev]`.
- 2026-01-10: `pip install -e '.[dev]'` failed with `externally-managed-environment` → used `.venv/bin/pip` inside a venv.

## Runs
### 2026-01-10 Setup: worktree + task
- Command:
  - `gh issue create ...` → #316
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "316" "prod-e2e-r041-remove-stub-llm"`
  - `rulebook_task_create issue-316-prod-e2e-r041-remove-stub-llm`
  - `rulebook_task_validate issue-316-prod-e2e-r041-remove-stub-llm`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/316`
  - `Worktree created: .worktrees/issue-316-prod-e2e-r041-remove-stub-llm`
  - `Branch: task/316-prod-e2e-r041-remove-stub-llm`
- Evidence:
  - (this file)

### 2026-01-10 Validation: venv + ruff + pytest
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `171 passed, 5 skipped`
- Evidence:
  - (this file)
