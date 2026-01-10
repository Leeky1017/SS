# ISSUE-267
- Issue: #267
- Branch: task/267-llm-draft-vars
- PR: https://github.com/Leeky1017/SS/pull/268

## Goal
- Make `/v1/jobs/{job_id}/draft/preview` populate `outcome_var` / `treatment_var` / `controls` from Claude Opus 4.5 output (while keeping stub/non-JSON fallback behavior).

## Status
- CURRENT: PR opened; waiting for required checks + auto-merge.

## Next Actions
- [x] Add draft-preview prompt builder (requirement + column candidates) and JSON parser into Draft fields.
- [x] Add unit tests for JSON parsing + persistence.
- [x] Run `ruff check .` and `pytest -q`.
- [ ] Enable auto-merge; verify merged; sync + cleanup worktree.

## Decisions Made
- 2026-01-10: Prefer "JSON-only" LLM output for structured draft fields, but keep non-JSON compatibility for stub/fallback.

## Errors Encountered
- None yet.

## Runs
### 2026-01-10 Setup: Issue + worktree
- Command:
  - `gh issue create -t "[OPS] SS: draft preview variable extraction (Opus 4.5)" -b "..."`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "267" "llm-draft-vars"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/267`
  - `Worktree created: .worktrees/issue-267-llm-draft-vars`
  - `Branch: task/267-llm-draft-vars`
- Evidence:
  - (this file)

### 2026-01-10 Implement: LLM JSON draft preview parsing
- Command:
  - Edit `src/domain/draft_service.py` to build a JSON-only prompt and parse response into Draft fields.
  - Add `src/domain/draft_preview_llm.py` prompt + parser helpers.
  - Add unit tests.
- Key output:
  - Draft preview now supports JSON LLM responses: `draft_text` / `outcome_var` / `treatment_var` / `controls` / `default_overrides`.
  - Non-JSON output remains supported (returns legacy draft text, variables stay unset).
- Evidence:
  - `src/domain/draft_service.py`
  - `src/domain/draft_preview_llm.py`
  - `tests/test_draft_preview_llm_json.py`

### 2026-01-10 Local checks
- Command:
  - `ruff check .`
  - `pytest -q`
- Key output:
  - `All checks passed!`
  - `162 passed, 5 skipped`
- Evidence:
  - N/A

### 2026-01-10 Preflight + PR
- Command:
  - `scripts/agent_pr_preflight.sh`
  - `gh pr create ...`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `https://github.com/Leeky1017/SS/pull/268`
- Evidence:
  - PR: https://github.com/Leeky1017/SS/pull/268
