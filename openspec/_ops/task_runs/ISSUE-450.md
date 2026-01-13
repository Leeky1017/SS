# ISSUE-450
- Issue: #450
- Branch: task/450-draft-preview-enhance
- PR: <fill-after-created>

## Goal
- Enhance `draft_preview` LLM schema to v2 so draft extraction supports panel/DID/IV setups (time/entity/cluster/FE/interactions/instruments).

## Plan
- Write spec delta + run log (spec-first)
- Implement v2 prompt + parser (v1 fallback)
- Add unit tests, update canonical spec, run `ruff`/`pytest`, open PR + auto-merge

## Status
- CURRENT: Implementation + tests green; preparing PR + auto-merge.

## Next Actions
- [ ] Create PR and enable auto-merge
- [ ] Verify required checks are green
- [ ] Verify PR is MERGED, sync controlplane, cleanup worktree

## Decisions Made
- 2026-01-13: Keep v1 JSON parsing as fallback for backward compatibility.

## Errors Encountered
- None yet.

## Runs
### 2026-01-13 23:01 Worktree + Rulebook task setup
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "450" "draft-preview-enhance"`
  - `rulebook task create issue-450-draft-preview-enhance`
  - `rulebook task validate issue-450-draft-preview-enhance`
- Key output:
  - `Worktree created: .worktrees/issue-450-draft-preview-enhance`
  - `✅ Task issue-450-draft-preview-enhance created successfully`
  - `✅ Task issue-450-draft-preview-enhance is valid`
- Evidence:
  - `rulebook/tasks/issue-450-draft-preview-enhance/`

### 2026-01-13 23:05 Validate task (spec delta added)
- Command:
  - `rulebook task validate issue-450-draft-preview-enhance`
- Key output:
  - `✅ Task issue-450-draft-preview-enhance is valid`
- Evidence:
  - `rulebook/tasks/issue-450-draft-preview-enhance/specs/ss-llm-brain/spec.md`

### 2026-01-13 23:20 Lint (ruff)
- Command:
  - `.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`
- Evidence:
  - `src/domain/draft_preview_llm.py`

### 2026-01-13 23:21 Unit tests (pytest)
- Command:
  - `.venv/bin/pytest -q`
- Key output:
  - `366 passed, 5 skipped`
- Evidence:
  - `tests/unit/test_draft_preview_llm.py`
