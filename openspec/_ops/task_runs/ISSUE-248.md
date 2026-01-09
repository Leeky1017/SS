# ISSUE-248
- Issue: #248
- Branch: task/248-delivery-autonomous-merge
- PR: https://github.com/Leeky1017/SS/pull/250

## Goal
- Ensure auto-merge cannot be silently abandoned: agent must verify PR is actually `MERGED`, and scripts/specs provide deterministic blocker handling (review required / behind / conflicts).

## Plan
- Update `scripts/agent_pr_automerge_and_sync.sh` to verify merge and handle common blockers (auto-rebase when behind; optional admin merge attempt when review required).
- Update `openspec/specs/ss-delivery-workflow/` and `AGENTS.md` to make merge verification a hard gate.

## Runs
### 2026-01-09 setup
- Command: `scripts/agent_worktree_setup.sh "248" "delivery-autonomous-merge"`
- Key output: `Worktree created: .worktrees/issue-248-delivery-autonomous-merge`

### 2026-01-09 rulebook
- Command: `rulebook task create issue-248-delivery-autonomous-merge`
- Key output: `✅ Task issue-248-delivery-autonomous-merge created successfully`

### 2026-01-09 rulebook
- Command: `rulebook task validate issue-248-delivery-autonomous-merge`
- Key output: `✅ Task issue-248-delivery-autonomous-merge is valid`

### 2026-01-09 validate
- Command: `bash -n scripts/agent_pr_automerge_and_sync.sh`
- Key output: `OK`

### 2026-01-09 validate
- Command: `openspec validate --specs --strict --no-interactive`
- Key output: `Totals: 25 passed, 0 failed (25 items)`
